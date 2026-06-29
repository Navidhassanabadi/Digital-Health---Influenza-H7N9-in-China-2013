

# Libraries used in this app:
# shiny     -> builds the interactive web app (UI + server)
# ggplot2   -> creates the plots
# dplyr     -> data wrangling (filter, mutate, count, etc.)
# tidyr     -> drop_na() for removing missing values
# outbreaks -> provides the real zoonotic dataset (fluH7N9_china_2013)

# Auto-install required packages (only installs what's missing)
packages <- c("shiny", "ggplot2", "dplyr", "tidyr", "outbreaks")
missing <- packages[!packages %in% rownames(installed.packages())]
if (length(missing) > 0) {
  install.packages(missing, dependencies = TRUE)
}
invisible(lapply(packages, library, character.only = TRUE))

# Get the dataset directly from the outbreaks package
df_raw <- outbreaks::fluH7N9_china_2013

# Prepare a clean dataset for the app
# NOTE: in this dataset `age` is a factor that contains "?" for unknown ages,
# and gender is coded "m"/"f". We clean both, build age groups, and group the
# many small provinces into "Other" so the charts stay readable.
main_provinces <- c("Shanghai", "Jiangsu", "Zhejiang")

df <- df_raw %>%
  mutate(
    age = suppressWarnings(as.numeric(as.character(age))),  # "?" -> NA
    gender = factor(gender, levels = c("m", "f"),
                    labels = c("Male", "Female")),
    outcome = factor(outcome, levels = c("Death", "Recover"),
                     labels = c("Death", "Recover")),
    province = ifelse(as.character(province) %in% main_provinces,
                      as.character(province), "Other"),
    province = factor(province,
                      levels = c("Shanghai", "Jiangsu", "Zhejiang", "Other")),
    age_group = cut(
      age,
      breaks = c(0, 18, 40, 60, 120),
      right = FALSE,
      labels = c("<18", "18-39", "40-59", "60+")
    )
  ) %>%
  select(date_of_onset, age, age_group, gender, outcome, province) %>%
  tidyr::drop_na(age, gender)   # keep rows with known age & gender

ui <- fluidPage(
  titlePanel("Clinical Shiny App - Avian Influenza A(H7N9), China 2013"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("gender", "Sex",
                  choices = c("All", levels(df$gender)), selected = "All"),
      selectInput("outcome", "Outcome",
                  choices = c("All", levels(df$outcome)), selected = "All"),
      selectInput("province", "Province",
                  choices = c("All", levels(df$province)), selected = "All"),
      sliderInput(
        "age", "Age range",
        min = floor(min(df$age, na.rm = TRUE)),
        max = ceiling(max(df$age, na.rm = TRUE)),
        value = c(floor(min(df$age, na.rm = TRUE)),
                  ceiling(max(df$age, na.rm = TRUE))),
        step = 1
      )
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Age groups",        plotOutput("barPlot",  height = 320)),
        tabPanel("Province vs age",   plotOutput("heatPlot", height = 360)),
        tabPanel("Epidemic curve",    plotOutput("timePlot", height = 320)),
        tabPanel("Age distribution",  plotOutput("histAge",  height = 320))
      )
    )
  )
)

server <- function(input, output) {
  
  # Central reactive: filter the data by every control
  filtered_data <- reactive({
    d <- df %>% filter(age >= input$age[1], age <= input$age[2])
    if (input$gender   != "All") d <- d %>% filter(gender   == input$gender)
    if (input$outcome  != "All") d <- d %>% filter(outcome  == input$outcome)
    if (input$province != "All") d <- d %>% filter(province == input$province)
    d
  })
  
  empty_msg <- function() {
    plot.new(); text(0.5, 0.5, "No data for the selected filters", cex = 1.2)
  }
  
  # 1) Cases by age group
  output$barPlot <- renderPlot({
    d <- filtered_data(); if (nrow(d) == 0) return(empty_msg())
    d %>%
      count(age_group) %>%
      ggplot(aes(age_group, n)) +
      geom_col(fill = "#2c6e91") +
      theme_minimal(base_size = 14) +
      labs(x = "Age group", y = "Patients", title = "Cases by age group")
  })
  
  # 2) Province x age-group heatmap
  output$heatPlot <- renderPlot({
    d <- filtered_data(); if (nrow(d) == 0) return(empty_msg())
    tab <- as.data.frame(table(d$province, d$age_group))
    names(tab) <- c("province", "age_group", "n")
    ggplot(tab, aes(x = age_group, y = province, fill = n)) +
      geom_tile(colour = "white") +
      scale_fill_gradient(low = "#e8f1f5", high = "#2c6e91") +
      theme_minimal(base_size = 14) +
      labs(x = "Age group", y = "Province", title = "Cases by province and age")
  })
  
  # 3) Epidemic curve (cumulative cases by date of onset)
  output$timePlot <- renderPlot({
    d <- filtered_data(); if (nrow(d) == 0) return(empty_msg())
    d %>%
      filter(!is.na(date_of_onset)) %>%
      count(date_of_onset) %>%
      arrange(date_of_onset) %>%
      mutate(cum_n = cumsum(n)) %>%
      ggplot(aes(date_of_onset, cum_n)) +
      geom_line(colour = "#2c6e91", linewidth = 1) +
      geom_point(colour = "#2c6e91") +
      theme_minimal(base_size = 14) +
      labs(x = "Date of onset (2013)", y = "Cumulative patients",
           title = "Epidemic curve")
  })
  
  # 4) Age distribution
  output$histAge <- renderPlot({
    d <- filtered_data(); if (nrow(d) == 0) return(empty_msg())
    ggplot(d, aes(age)) +
      geom_histogram(bins = 15, fill = "#2c6e91") +
      theme_minimal(base_size = 14) +
      labs(x = "Age", y = "Patients", title = "Age distribution")
  })
}

shinyApp(ui, server)