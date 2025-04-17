# IndiPHARM-Task5
## Automated Plasma Sample Preparation with Opentrons Flex

This repository contains .py protocols and a corresponding SOP using the **Opentrons Flex robotic liquid handler**. You can use these protocols to prepare up to **80 plasma samples and 16 QA/QC samples in a 96-well plate in under one hour**. This method has been validated to be accurate, precise, and reproducible. We encourage parties interested in automating sample preparation to use our protocols!

---

### Repository Contents

- `protocols/`  
  Contains Python (`.py`) scripts compatible with the Opentrons Flex platform. The two scripts correspond to two parts of sample prep:
  - 1: Sample transfer and extraction solvent addition " .py"
  - 2: Dilution and Supernatant transfer " .py"

- `docs/`  
  Includes our complete Standard Operating Procedure (SOP) in PDF format, with:
  - Overview and safety notes
  - Material lists and reagent volumes
  - Software setup instructions
  - Step-by-step instructions

- `labware/`  
  All custom labware definitions (.json files) needed in the protocols provided.

---

### Requirements

- Opentrons Flex robotic liquid handler
- Opentrons App (Version at time of upload: 8.3.1 ; api level _)
- [Python API](https://docs.opentrons.com/v2/) support for custom scripts
- Required Opentrons hardware:
  - Multi-channel pipette (Flex-compatible)
  - Temperature modules (2)

---

### How to Use

1. Download the `.py` protocol files.
2. Review the SOP PDF in the `docs/` folder.
4. Open the first `.py` script in the Opentrons App. Analyze and select.
5. Set up the deck layout according to the SOP and map view on the app.
7. Start the run and watch your samples prepped in minutes.
8. Continue to follow instructions on the SOP for the second protocol.
9. Enjoy low CVs and more free time!   

---

### Validation & Performance

These protocols have been validated across multiple runs using:

- Gravimetric QA/QC: to confirm volumetric accuracy and precision across all steps of both protocols. 
- HPLC/HRMS Analysis: to assess downstream precision; results showed: 
  - Low coefficient of variation (CV%) across pooled plasma samples

---

### Contributing

We welcome collaboration and feedback. Please submit issues or pull requests if:
- You adapt the protocol to other matrices (e.g., serum, urine)
- You identify improvements or bugs
- You need help customizing for different deck layouts

### Acknowledgments

This work was developed by **The CLUES Lab at the Gangarosa Department of Environmental Health Sciences @ Emory University** for **IndiPHARM: Individual Metabolome and Exposome Assessment for Pharmaceutical Optimization** , with support from **ARPA-H**.  
