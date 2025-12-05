####################################################################        ######################################                                                                ######################################
                                                                            #                                    #                                                                #                                    #
# Micronic Plate reader .csv --> Sequence List Generator Script             #      CLICK 'RUN APP' ^^^           #                                                                #      CLICK 'RUN APP' ^^^           #
# Hands-free ARPA-H sample tracking                                         #      CLICK 'RUN APP' ^^^           #                                                                #      CLICK 'RUN APP' ^^^           #
# Click 'Run App' in top right corner >>>                                   #                                    #                                                                #                                    #
                                                                            ######################################                                                                ######################################
####################################################################
rm(list=ls()) #clear environment

######################### EDIT FOR EACH STUDY #########################################

#### VERSION info ####################################

## Study affiliations: CLU0132 (PFAS EIR)                         <- ENTER STUDY AFFILIATION
## Creation date: 251110. Updated for PFAS EIR study              <- ENTER DATE

### STUDY FILE PATHS #################################

# QAQC inventory (permanent; all study)
q_filepath <- "R:/diwalke/LC/Run_Lists/Accelerated_Methods/QAQCS-Comprehensive_Updated251117.xlsx" # update name if this changes
# Samples inventory (study-specific; inside study folder)
s_filepath <- file.path("..", "Samples.xlsx")                     # <- ENTER SAMPLES WORKBOOK NAME

# Name of RAW files and sequence folder, date does not change
study_foldername <- "CLU0XXX_YYMMDD_Study_Name"                   # <- ENTER OUTPUT FOLDER NAME (DOES NOT CHANGE)

########################################################################################

# List of required packages
required_packages <- c(
  "openxlsx", "shinyjs", "tools",
  "shiny", "readr", "dplyr", 
  "plotly", "readxl", "shinyFiles", "stringr", "this.path"
)

# Install any that are missing
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  } else {
    library(pkg, character.only = TRUE)
  }
}

# Set the wd to the folder the app is in - MORE ROBUST with this.path changed 7/29
setwd(this.dir())

qaqcs <- read_excel(q_filepath, sheet = "QAQCs", col_types = "text")
qaqcs$Analyzed <- as.logical(qaqcs$Analyzed)

samples <- read_excel(s_filepath, sheet = "Samples", col_types = "text")
samples$Analyzed <- as.logical(samples$Analyzed)
# altering?

qaqc_inventory <- qaqcs
sample_inventory <- samples

load("App/Mapping/map.Rdata")  # loads 'df' (96-positions and orders) and 'map' (384-positions)

# run the app or press the Run App button ^^
runApp("App")
