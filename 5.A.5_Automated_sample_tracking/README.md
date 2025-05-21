# IndiPHARM-Task5
## Automated sample tracking and LCMS sequence list generator - coming soon!

Sample tracking and LCMS sequence list generation all-in-one for the CLUES lab.

The goal of this program is to avoid copy/pasting, manual interventions, and human error when preparing LCMS sequence lists. Additionally, the integration with the OpenSpecimen online sample tracking database (in development) eliminates the need for manual sample tracking. 

The Shiny app user interface accepts .csv files from your Micronic plate scanner. It arranges up to 4 plates into a 384-well plate run list. Check and make sure your samples and QAQCs are labeled and arranged as expected. Then enter LC run information and generate ready-to-run C18 + HILIC sequence lists in one click! 


Instructions**:

1. How to load the app: 
Option 1: Clone the repository and run the app locally
```
# First, use git from your terminal:
# git clone https://github.com/CLUES-Emory/IndiPHARM-Task5.git

# Then in R, navigate to the directory and run the app:
library(shiny)
setwd("path/to/cloned/IndiPHARM-Task5/5.A.5_Automated_sample_tracking")
runApp()
```

Option 2: Use runGitHub() function provided by shiny package - no download required

```
# Install shiny if you haven't already
if (!require("shiny")) install.packages("shiny")

# Run the app directly from GitHub
library(shiny)
runGitHub("IndiPHARM-Task5", "CLUES-Emory", subdir = "5.A.5_Automated_sample_tracking")
```

Once in the app,
1. Upload 1-4 Micronic RackData .csv files. Specify sample/QAQC plate. The app assumes plates are transfered into a 384-well plate in an alternating pattern, where the top left corner of Plate 1 falls into A1 of the 384 well plate, the top left corner of Plate 2 --> A2, Plate 3 --> B1, Plate 4 --> B2.

2. The app will order the Matrix IDs from the plate scans into a 384-well plate. Check for accuracy. Choose whether to update the sample inventory to indicate your samples are being analyzed.

3. The app will search the study inventory, label QAQC samples, and check Matrix IDs. Check for accuracy.

4. Add LC Run Info (date, technician, machine) and the will generate your sequence lists ready for LCMS analysis.

## Instructions on how to organize your sample inventory 

Coming soon.

# Project Repository Structure

├── App/
│   ├── ui.R                  User interface code for the Shiny application
│   └── server.R              Server-side logic for the Shiny application
│
├── Generated_Sequences/      Contains output files from sequence generation
│   └── ...                   Various output files
│
├── Mapping/                  Contains mapping files for plate formats
│   └── ...                   Files used to map 96-well plates to 384-well plate
│
├── PlateScans/               Contains plate scan data
│   └── ...                   .CSV files generated with Micronic plate scanner
│
├── c18_lines.R               R script for c18 lines processing
├── hilic_lines.R             R script for HILIC lines processing
├── run_app.R                 Script to launch the Shiny application
├── run_parameters.R          Configuration parameters for running the application
├── TestCopy_250409_CLU0120_Plate_Loading_Q...  Excel file with study inventory data (will be moved to OpenSpecimen)


