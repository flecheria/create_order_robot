*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...                 Make Log.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Robocloud.Items
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    # Open website and overcome welcome message
    Open website
    # Download CSV
    ${orders} =    Read CSV
    # Complete Order Form Test
    FOR    ${order}    IN    @{orders}
        Test for Alert
        Overcome welcome message
        Complete Order Form    ${order}
        ${file_name} =    Capture preview of the robot    ${order}
        Confirm the order
        Test for order confirmation

        ${data} =    Get data for PDF
        Log To Console    ${data}
        ${fulltext} =    Create HTML for PDF    ${data}    ${order}
        ${pdf_file_name} =    Create PDF path    ${order}
        Html To Pdf    ${fulltext}    ${OUTPUTDIR}/pdf/${pdf_file_name}
        Make another order
    END

    Create ZIP package from PDF files
    Remove directory    ${OUTPUTDIR}/pdf    recursive=${True}
    [Teardown]    Close Browser


*** Keywords ***
Open website and overcome welcome message
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Element Is Visible    class:modal
    Click Button    class:btn.btn-dark

Open website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Overcome welcome message
    Wait Until Element Is Visible    class:modal
    Click Button    class:btn.btn-dark

Download CSV
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Read CSV
    [Documentation]    Read and return csv as a table
    ${orders} =    Read table from CSV    orders.csv    header=TRUE
    RETURN    ${orders}

Complete Order Form Test
    # assign head values
    Select From List By Value    head    1
    # assign body value
    Select Radio Button    body    3
    # assign legs value
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    2
    # assign address
    Input Text    name:address    Address 123

Complete Order Form
    [Documentation]    Insert the single order and return image of the robot
    [Arguments]    ${order}
    Wait Until Element Is Visible    class:custom-select
    Select From List By Value    class:custom-select    ${order}[Head]
    # assign body value
    Select Radio Button    body    ${order}[Body]
    # assign legs value
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    # assign address
    Input Text    name:address    ${order}[Address]
    # capture the robot screenshot
    Capture preview of the robot    ${order}

Capture preview of the robot
    [Documentation]    Capture the preview of the robot clicking on Preview button
    [Arguments]    ${order}
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    ${test} =    Catenate    ${order}[Order number]    .png
    ${file_name} =    Catenate    robot_preview_    ${test}
    Capture Element Screenshot    id:robot-preview-image    ${OUTPUTDIR}/${file_name}
    RETURN    ${file_name}

Confirm the order
    [Documentation]    Confirm the order clicking on Order button
    Click Button    id:order

Make another order
    [Documentation]    Make another order
    Click Button    id:order-another
    Wait Until Element Is Visible    class:modal-body

Get data for PDF
    [Documentation]    Collect data for PDF
    ${title} =    Get Text    xpath://*[@id="receipt"]/h3
    ${time} =    Get Text    xpath://*[@id="receipt"]/div[1]
    ${robot_order} =    Get Text    xpath://*[@id="receipt"]/p[1]
    ${head} =    Get Text    xpath://*[@id="parts"]/div[1]
    ${body} =    Get Text    xpath://*[@id="parts"]/div[2]
    ${legs} =    Get Text    xpath://*[@id="parts"]/div[3]
    ${thanks} =    Get Text    xpath://*[@id="receipt"]/p[3]
    RETURN    ${{ "<br>".join(["<br>", $title, $time, $robot_order, $head, $body, $legs, $thanks]) }}

Create HTML for PDF
    [Documentation]    Create PDF with text
    [Arguments]    ${text}    ${order}
    ${img_path} =    Catenate    ${OUTPUTDIR}/robot_preview_    ${order}[Order number]
    ${img_path} =    Catenate    ${img_path}    .png
    RETURN    ${{ "<div><p>{0}</p><img src=\"{1}\"</div>".format($text, $img_path) }}

Create PDF path
    [Documentation]    Format file path for pdf
    [Arguments]    ${order}
    ${order_number} =    Catenate    robot_output_    ${order}[Order number]
    RETURN    ${{ "".join([$order_number, ".pdf"]) }}

Make Log
    Log    Done.

Test for Alert
    ${test} =    Set Variable    True
    WHILE    ${test}
        ${test} =    Is Element Visible    class:alert-danger
        Reload Page
        Wait Until Element Is Visible    class:modal-body
    END

Test for order confirmation
    ${test} =    Set Variable    True
    WHILE    ${test}
        ${test} =    Is Element Visible    class:alert-danger

        IF    ${test}
            Confirm the order
            # ${test} =    Is Element Visible    id:order-completion
        END
    END

Create ZIP package from PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}/pdf    ${OUTPUT_DIR}/PDFs.zip