# Clinical Shiny App – Avian Influenza A(H7N9) in China

This repository contains a simple, interactive Shiny application built using real-world epidemiological data. It visualizes the 2013 outbreak of the zoonotic avian influenza A(H7N9) virus in China.

## Dataset
The app uses the `fluH7N9_china_2013` dataset provided by the `outbreaks` R package. This dataset contains 136 human cases collated from ProMED, the World Health Organization (WHO), and research articles. It tracks variables such as age, gender, province, date of onset, and clinical outcome.

Documentation for the dataset can be found within the outbreaks package:
https://cran.r-project.org/web/packages/outbreaks/index.html

## Features
- **Interactive Filtering:** Filter outbreak cases by Age, Sex, Outcome, and Province.
- **Age Group Bar Chart:** View patient counts categorized by age brackets.
- **Regional Heatmap:** Compare case distributions across major provinces by age.
- **Epidemic Curve:** Track the cumulative growth of the outbreak over time.
- **Robust Error Handling:** The app displays a friendly message if filter combinations result in empty data.

## Requirements
- R (>= 4.0)
- RStudio
- Internet connection (for the automatic package installation script to run)

## How to run
1. Open the `app.R` file in RStudio.
2. Click the **Run App** button in the top right corner of the script editor.

*Note: The script includes an automated check. If you do not have the required packages (`shiny`, `ggplot2`, `dplyr`, `tidyr`, `outbreaks`) installed, the script will automatically install them for you before launching the application.*
