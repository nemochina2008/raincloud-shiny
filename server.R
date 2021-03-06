#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

source("source/libraries.R", local = TRUE)
source("source/createPlot.R", local = TRUE)
source("source/formatCode.R", local = TRUE)
source("source/downloadPlot.R", local = TRUE)
source("source/dataUpload.R", local = TRUE)

server <- function(input, output, session) {
  
  processedData <- callModule(dataUploadAndManipulation, "rainCloud")

  # Conditions to upload the UI if necessary
  # output$statsControlUI <- renderUI({
  #   conditionList <- as.list(processedData$conditions())
  #   selectInput("statsControl", 
  #                      label = h4("Control Condition"),
  #                      choices = conditionList, 
  #                      selected = conditionList[[1]])
  # })
  
  output$statsCombinationsUI <- renderUI({
    # This is wrong on so many levels but is the only way I found it f** works.
    # Explanation: ggghost accepts only 1 supplemental data, which is 'input'.
    #   Therefore, we need the list of comparisons to be an input.
    #   Should be something like list('AvsB' = c('A', 'B'),
    #                                 'BvsC' = c('B', 'C'))
    #   The problem here is that there is not any input that can accept a vector
    #   as values.
    #   We could use selectInput multiple == TRUE (see previous attempts), but 
    #   then it would group the values as independent under the same name (e.g).
    #   AvsB
    #   ----
    #   A
    #   B
    #   BvsC
    #   ----
    #   B
    #   C
    #   This is a disaster.
    
    # # ## Create a matrix with the combinations
    # statsCombns <- combn(processedData$conditions(), 2)
    #  
    # # ## From the split examples: split a matrix into a list by columns
    # combinationList <- split(statsCombns, col(statsCombns))
    # 
    # # ## Name the List
    # combinationListNames <- combn(processedData$conditions(), 2, FUN = paste, collapse = 'vs')
    # names(combinationList) <- combinationListNames
    # print(combinationList)
    # checkboxGroupInput('statsCombinations',
    #                    label = h4("Conditions To Test"),
    #                    choices = combinationList)
    
    combinationList <- combn(processedData$conditions(), 2, FUN = paste, collapse = 'vs')
    selectInput("statsCombinations", 
                label = h4("Conditions To Test"),
                choices = combinationList,
                multiple = TRUE)
    
  })

  # Render the uploaded Data
  # output$rainCloudData <- renderDataTable({
  #   processedData$df()
  # })

  returnPlot <- reactive({
    createPlot(
      input = input,
      plotData = processedData$df()
    )
  })

  output$rainCloudPlot <- renderPlot(returnPlot()$plot,
    height = function(x) input$height,
    width = function(x) input$width
  )

  # Print the summary code
  output$rainCloudCode <- renderPrint({
    plotSummary <- returnPlot()$summary
    
    summaryPrint <- reactive({
      formatCode(
        input = input,
        code = plotSummary
      )
    })
    print(h3("Relevant Plot Code"))
    print(tags$small("Please take into account that some of code below may be a bit unorthodox
               due to dealing with input constraints."))
    tags$pre(summaryPrint())
  })

  output$rainCloudpng <- callModule(downloadPlot, id = "rainCloudpng",
                                    plot = last_plot(),
                                    fileType = "png",
                                    width = input$width / 72,
                                    height = input$height / 72)
  output$rainCloudtiff <- callModule(downloadPlot, id = "rainCloudtiff", 
                                    plot = last_plot(),
                                    fileType = 'tiff',
                                    width = input$width / 72,
                                    height = input$height / 72)
  output$rainCloudpdf <- callModule(downloadPlot, id = "rainCloudpdf",
                                    plot = last_plot(),
                                    fileType = "pdf",
                                    width = input$width / 72,
                                    height = input$height / 72)
  
  # Should probably move that but it's convenient while editing.
  output$rainCloudAbout <- renderUI ({
    HTML("<h2>Raincloud Plots</h2>
<p>The idea behind Raincloud plots was introduced by <a href='https://micahallen.org/2018/03/15/introducing-raincloud-plots/'>Micah Allen on his blog</a>. My coworkers and I found it really interesting to display our data but they did not have any R experience, so I made this shiny app to provide a smooth transition to R and ggplot.</p>
<p>Please cite the preprint (<a href='https://peerj.com/preprints/27137v1/'>here</a>) if you use it in any kind of publication.</p>
<small>The source code for this shiny app can be found in <a href='https://github.com/gabrifc/raincloud-shiny'>Github</a></small>
")
  })
}
