## IndiPHARM-Task5
## Automated sample tracking and LCMS sequence list generator for generating a sequence list of up to 288 study samples + 96 QAQC samples (384-well plate).

The goal of this program is to provide hands-free sample tracking and LCMS sequence list generation for the indiPHARM project. 

The Shiny app user interface accepts .csv files from your Micronic plate scanner. It arranges up to 4 plates into a 384-well plate run list. Check and make sure your samples and QAQCs are labeled and arranged as expected. Then enter LC run information and generate ready-to-run C18 + HILIC sequence lists in one click! \

Required equipment: Micronic 96-tube matrix rack scanner, Opentrons Flex Automated Liquid Handler, and an LC-HRMS instrument (optimized for Orbitrap).


Instructions:
SETUP
1. Create your study folder. Inside the main study folder, add a QAQCs and Samples workbook with Matrix IDs and Sample IDs. These will be used for tracking and generating a sequence for LC analysis. Make sure to match the column names to the example.
2. Inside the sequence generator app folder, open RUN.R and edit lines 13-23 (most important - paths to your Samples and QAQC sheets.)
3. Scan your study racks and QAQC rack using the Microic plate scanner. Ensure the settings create an output like the example in this folder.
3. In RStudio, open Run.R if not already open. Ensure all paths are correct. Click 'Run App'
4. Upload your plate scans in the order they will be aliquoted in the Opentrons protocol. 
5. Follow the remaining instructions in the protocol for the sequence generator to output C18 and HILIC sequence lists.



RUNNING THE APPLICATION
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
f
Option 2: Use runGitHub() function provided by shiny package - no download required

```
# Install shiny if you haven't already
if (!require("shiny")) install.packages("shiny")

# Run the app directly from GitHub
library(shiny)
runGitHub("IndiPHARM-Task5", "CLUES-Emory", subdir = "5.A.5_Automated_sample_tracking")
```

Once in the app,
1. Upload 1-4 Micronic RackData .csv files. Specify sample/QAQC plate. 
    The app assumes plates are transfered into a 384-well plate in an alternating pattern, where the top left corner of Plate 1 falls into A1 of the 384 well plate, the top left corner of Plate 2 --> A2, Plate 3 --> B1, Plate 4 --> B2.

2. The app will order the Matrix IDs from the plate scans into a 384-well plate. Check for accuracy. Choose whether to update the sample inventory to indicate your samples are being analyzed.

3. The app will search the study inventory, label QAQC samples, and check Matrix IDs. Check for accuracy.

4. Add LC Run Info (date, technician, machine) and the will generate your sequence lists ready for LCMS analysis.

```
