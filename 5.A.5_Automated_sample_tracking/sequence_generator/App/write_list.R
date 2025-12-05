################################################################################################
# Order in this file (originally for SWAN / CLU0116):
################################################################################################

# 1 real blank (front and back labeled 'Blank', middle labeled 'Cal_Std')
# 1 water (out of 2)
# 1 NIST (OPTIONAL, out of 1)
# 1 AMAP (optional, out of 1)

# 3 PFAS baby cal curve (0.1, 1, 10)
# PFAS QAQC (3/3)

# HRE Pool 1 
# HRE Pool 2
# 40 study samples
# HRE Pool 1
# HRE Pool 2
# 40 study samples
# HRE Pool 1
# HRE Pool 2

# PFAS QAQC (2/3)
# 1 'blank' 
# BIG CAL CURVE (1-8/8)
# 1 'blank' 

# HRE Pool 1
# HRE Pool 2
# 40 study samples
# HRE Pool 1
# HRE Pool 2
# 40 study samples

# HRE Pool 1
# HRE Pool 2

# PFAS QAQC (3/3)
# 3 PFAS baby cal curve (0.1, 1, 10)

# 1 water (out of 2)
# 1 real blank

### HANDLING
# Expecting 80 samples per plate (2 plates)
# If only one plate: only run the first half of QAQCs + cal curve.
# If a plate has 60+: split in half
# If a plate has <60: run in one chunk.

#############################################################

############### NOTES ABOUT SAMPLE LOGIC BY TYPE

#' total_count: rows that are not NA in Sample_ID** FIX
#' cal_curves: rows that start with 'FBS'
#' cc_count: number of rows that start with 'FBS'
#' MDL handling: code removes duplicate cal curve from cal_curves and assigns duplicate to mdls
#' pools: rows that start with 'HRE'
#' pool_count: number of rows of pools
#' pools1: pools that start with HRE and have .p1
#' pools2: pools that start with HRE and have .p2

#' waters: rows that start with 'Water'
#' water_count: number of rows of waters
#' 
#' OPTIONAL
#' amaps: rows that start with 'AMAP'
#' amap_count: number of rows of amaps
#' nists: rows that start with 'NIST'
#' nist_count: number of rows of nists
#' 
#' ## STUDY SAMPLES LOGIC #################
#' identify as 'sampletype == 'Study_Sample' (good logic)
#' 
#' total_samples: sum of cc_count + water_count + amap_count + nist_count + study_sample_count
#' 
#' ^ check against total_count, mismatches

### MSMS LOGIC
# if study_samples$pfms == TRUE then there is a PFAS MSMS run after that sample
# if study_samples$nonpfms == TRUE then there is a nonPFAS MSMS run after that sample

###########################################################################################

### Passing arguments directly with function -- 7/31 change
write_sequence <- function(params) {
  date <- params$date 
  study <- params$study 
  batch <- params$batch 
  rack <- params$rack 
  tech <- params$tech 
  machine <- params$machine
  set <- params$set # added 11/11
  pos <- params$pos
  hre_ms2 <- params$hre_ms2 # added 10/27
  
  final_data <- params$final_data 
  sequence_filename <- params$sequence_filename 
  sequence_filepath <- params$sequence_filepath 
  project_path <- params$project_path 
  output_path <- params$output_path 
  order_pattern <- params$order_pattern
  
  # TRIM WHITE SPACE 
  final_data$Sample_ID <- trimws(final_data$Sample_ID, which = "left")
  
  # Variables needed #######################################
  # Field 1
  sample_type <- 'Unknown' #always Unknown (for now?)
  
  # Field 2 - File Name
  # R or N?
  if (machine == 'C18') {
    if (set == "Ralph/Nancy") {
      letter <- 'R'
    } else if (set == "Charybdis/Scylla") {
      letter <- 'C'
    }
  } else if (machine == 'HILIC') {
    if (set == "Ralph/Nancy") {
      letter <- 'N'
    } else if (set == "Charybdis/Scylla") {
      letter <- 'S'
    }
  } 
  
  studynum <- sub("_.*$", "", study)
  
  filename_pos <- sprintf("%s%s_%s_%spos_", letter, date, studynum, machine)
  filename_neg <- sprintf("%s%s_%s_%sneg_", letter, date, studynum, machine)
  
  # Field 3 - Sample ID 
  # comes from dataframe by row
  
  # Field 4 - Comment 
  comment <- as.numeric(batch)
  
  # Field 5 - L2 Client
  l2 <- "add"
  
  ## CHANGING THE RACK ID LOGIC 8/21 ### 
  
  ## add a column for rack identification
  final_data$racknum <- sub(".*-", "", final_data$pos96)
  
  # split into first and second numbers
  rack_split <- str_split(rack, ",")[[1]]
  rack1 <- rack_split[1] # 7
  rack2 <- rack_split[2] # 8
  
  final_data <- final_data %>%
    mutate(
      rack = case_when(
        sampletype == "Study_Sample" & racknum == 1 ~ rack1,
        sampletype == "Study_Sample" & racknum == 2 ~ rack2,
        TRUE ~ NA_character_
      )
    )
  
  # Field 6 - PROJECT Path
  ## 7/31 change to be edited by user in last tab
  
  path <- project_path
  ms2path <- paste0(path, '\\MSMS') # fixed 10/27
  
  # Field 7 - ## Instrument Method ######################
  
  remote_method = TRUE # Remove option 10/27 for simplicity (for now)
  
  if (remote_method) {
    cat("Writing method paths (hardcoded; on remote machine)")
    
    if (machine == 'C18') {
      
      # 5 min methods 10/27
      
      reg_pos <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-C18\\251027_C18pos_Ch1-5min"
      reg_neg <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-C18\\251027_C18neg_Ch2-5min"
      
      ms2_pfas_pos <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-C18\\251027_C18pos_Ch1-5min_PFAS_MSMS"
      ms2_pfas_neg <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-C18\\251027_C18neg_Ch2-5min_PFAS_MSMS"
      
      ms2_nonpfas_pos <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-C18\\251027_C18pos_Ch1-5min_Sample_MSMS"
      ms2_nonpfas_neg <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-C18\\251027_C18neg_Ch2-5min_Sample_MSMS"
      
      ms2_pool_pos <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-C18\\251027_C18pos_Ch1-5min_HRE_MSMS"
      ms2_pool_neg <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-C18\\251027_C18neg_Ch2-5min_HRE_MSMS"
      
      # OLD METHODS
      
      # reg_pos <- "C:\\Xcalibur\\methods\\Aria_C18_Methods\\240408_C18pos_120k_BottomPump_Channel1"
      # reg_neg <- "C:\\Xcalibur\\methods\\Aria_C18_Methods\\240408_C18neg_120k_TopPump_Channel2"
      # 
      # ms2_pfas_pos <- "C:\\Xcalibur\\methods\\Aria_C18_Methods\\240802_C18pos_BottomPump_Channel1_Water_PFAS-inc-ddMS2"
      # ms2_pfas_neg <- "C:\\Xcalibur\\methods\\Aria_C18_Methods\\240802_C18neg_TopPump_Channel2_Water_PFAS-inc-ddMS2"
      # 
      # ms2_nonpfas_pos <- "C:\\Xcalibur\\methods\\Aria_C18_Methods\\240801_C18pos_BottomPump_Channel1_Water+PP-ddMS2"
      # ms2_nonpfas_neg <- "C:\\Xcalibur\\methods\\Aria_C18_Methods\\240801_C18neg_TopPump_Channel2_Water+PP-ddMS2"
      # 
      # ms2_pool_pos <- "C:\\Xcalibur\\methods\\Aria_C18_Methods\\240801_C18pos_BottomPump_Channel1_Water-ddMS2"
      # ms2_pool_neg <- "C:\\Xcalibur\\methods\\Aria_C18_Methods\\240801_C18neg_TopPump_Channel2_Water-ddMS2"

      
    } else if (machine == 'HILIC') {
      
      # 5 min methods 10/27
      
      reg_pos <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-HILIC\\251027_HILICpos_Ch1-5min"
      reg_neg <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-HILIC\\251027_HILICneg_Ch2-5min"
      
      ms2_pfas_pos <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-HILIC\\251027_HILICpos_Ch1-5min_PFAS_MSMS"
      ms2_pfas_neg <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-HILIC\\251027_HILICneg_Ch2-5min_PFAS_MSMS"
      
      ms2_nonpfas_pos <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-HILIC\\251027_HILICpos_Ch1-5min_Sample_MSMS"
      ms2_nonpfas_neg <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-HILIC\\251027_HILICneg_Ch2-5min_Sample_MSMS"
      
      ms2_pool_pos <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-HILIC\\251027_HILICpos_Ch1-5min_HRE_MSMS"
      ms2_pool_neg <- "C:\\Xcalibur\\methods\\Aria_Methods\\5min_Methods-HILIC\\251027_HILICneg_Ch2-5min_HRE_MSMS"
      
      #  OLD METHODS
      
      # reg_pos <- "C:\\Xcalibur\\methods\\Aria Methods\\240611_HILICpos_120k_BottomPump_Channel1"
      # reg_neg <- "C:\\Xcalibur\\methods\\Aria Methods\\240411_HILICneg_120k_TopPump_Channel2"
      # 
      # ms2_pfas_pos <- "C:\\Xcalibur\\methods\\Aria Methods\\240802_HILICpos_BottomPump_Channel1_Water_PFAS-inc-ddMS2"
      # ms2_pfas_neg <- "C:\\Xcalibur\\methods\\Aria Methods\\240802_HILICneg_TopPump_Channel2_Water_PFAS-inc-ddMS2"
      # 
      # ms2_nonpfas_pos <- "C:\\Xcalibur\\methods\\Aria Methods\\240801_HILICpos_BottomPump_Channel1_Water+PP-ddMS2"
      # ms2_nonpfas_neg <- "C:\\Xcalibur\\methods\\Aria Methods\\240801_HILICneg_TopPump_Channel2_Water+PP-ddMS2"
      # 
      # ms2_pool_pos <- "C:\\Xcalibur\\methods\\Aria Methods\\240801_HILICpos_BottomPump_Channel1_Water-ddMS2"
      # ms2_pool_neg <- "C:\\Xcalibur\\methods\\Aria Methods\\240801_HILICneg_TopPump_Channel2_Water-ddMS2"
      # 
    }
  } # end method path assignment
  
  # Field 8 - Position
  # Front is shiny input, end comes from pos384 in df
  position <- paste0(pos, ":") # finish by row
  
  # Field 9 = Inj Vol changed 10/27 for 5-min methods!
  if (machine == 'C18') {
    pos_vol <- "7.5"
    neg_vol <- "10"
  } else if (machine == 'HILIC') {
    pos_vol <- "1"
    neg_vol <- "1.5"
  } 
  
  # Field 10 - L1 Study
  l1 <- study
  # "CLU0120_MEC"
  
  # Field 11 - L3 Laboratory
  l3 <- tech
  
  # Field 12 - Sample Name
  # comes from dataframe by row
  
  #############################################################################
  # Count by sample type - needed for loops
  #############################################################################
  final_data$Sample_ID <- trimws(final_data$Sample_ID) #remove spaces 
  total_count <- sum(!is.na(final_data$Sample_ID)) #for checking
  
  ### CAL CURVES #####################################################################################
  # Edited 9/24 for little cal curve logic
  
  cal_curves <- final_data[grepl("FBS", final_data$Sample_ID), ] 
  cc_count <- nrow(cal_curves) #now includes the baby cal curve 9/24

  # order
  cal_curves <- cal_curves[order(cal_curves$Sample_ID), ]
  
  # Helper column that counts duplicates
  cal_curves$dup_index <- ave(cal_curves$Sample_ID, cal_curves$Sample_ID, FUN = seq_along)
  
  # Split the data ##########
  
  # Middle - large cal curve - one of each concentration ############
  cal_curve_big <- cal_curves[cal_curves$dup_index == 1, ] %>%
    mutate(
      conc = as.numeric(str_extract(Sample_ID, "[0-9.]+(?=ng-mL)"))  # extract numbers
    ) %>%
    arrange(conc) #try this fix for the numbers to be in chronological order
  
  #### Beginning and end - Baby cal curves ##################
  cal_curve_little <- cal_curves[cal_curves$dup_index > 1, ] %>%
    mutate(
      conc = as.numeric(str_extract(Sample_ID, "[0-9.]+(?=ng-mL)"))
    )

  cal_curve_little_list <- split(cal_curve_little, cal_curve_little$Sample_ID)
  
  # Reorder the list by concentration
  order_index <- order(sapply(cal_curve_little_list, function(x) unique(x$conc)))
  cal_curve_little_list <- cal_curve_little_list[order_index]
  
  # should be a list of 3 with 2 rows each
  
  ##### PFAS QAQCs (standalone, 'PFAS.p...') ################
  pfas_qaqcs <- final_data[grepl("^PFAS\\.p", final_data$Sample_ID), ]
  pfas_qaqc_count <- nrow(pfas_qaqcs) #3?
  
  ### POOLS ############# 
  pools <- final_data[grepl("^HRE", final_data$Sample_ID), ] 
  pool_count <- nrow(pools) 
  
  pools1 <- pools[grepl("^HRE\\.p1", pools$Sample_ID), ] # should be 6
  pools2 <- pools[grepl("^HRE\\.p2", pools$Sample_ID), ] # should be 6
  
  ###  WATERS ############
  waters <- final_data[grepl("^Water", final_data$Sample_ID), ]
  water_count <- nrow(waters)
  
  ###  AMAPS ############
  amaps <- final_data[grepl("^AM", final_data$Sample_ID), ]
  amap_count <- nrow(amaps)
  
  ###  NISTS ############
  nists <- final_data[grepl("^NIST", final_data$Sample_ID), ]
  nist_count <- nrow(nists)
  # OPTIONAL - if nist_count == 0
  
  ###  STUDY SAMPLES ############
  study_samples <- final_data[final_data$sampletype == 'Study_Sample' & !is.na(final_data$ID),]
  study_sample_count <- nrow(study_samples) #160 expected
  
  print(paste("Study samples found:", study_sample_count))
  
  # DEBUG: Check if study_samples is empty
  if(study_sample_count == 0) {
    print("No study samples found!")
  }
  
  ### ORDER STUDY SAMPLES BY THE ORDER (detected or manual override, see server code) 
  
  order_column <- if (order_pattern == "byrow") {
    "Row_order_by_plate"
  } else {
    "Col_order_by_plate"
  }
  ## ORDER BASED ON COLUMN ABOVE - works for both
  study_samples <- study_samples[order(study_samples[[order_column]]), ] ## 8/22 FIXED!
  
  # CHECK - count totals for next part and to check
  total_samples <- cc_count + pfas_qaqc_count + pool_count + water_count + amap_count + nist_count + study_sample_count
  
  if(total_count == total_samples) {
    print("All qaqcs and samples were identified!")
  } else {
    print(paste("Some samples were not identified. rows of dataframe =", total_count, "and sample types added together = ", total_samples))
  }
  # ^ for mismatch, print more info....?
  
  ###### ADJUSTING FOR SIZE OF SAMPLE RACKS #################
  
  unique_endings <- study_samples %>%
    mutate(ending = str_sub(pos96, -1)) %>%
    pull(ending) %>%
    unique() %>%
    sort()
  
  print(paste("Unique racks found:", paste(unique_endings, collapse = ", ")))
  
  ## For each rack number in study_samples (expecting 2),
  ## create new df rack#_samples with the samples from that rack only
  rack_samples_list <- list()
  
  # DEBUG: Only proceed if we have endings
  if(length(unique_endings) > 0) {
    for(ending in unique_endings) {
      # Filter samples and store in the list with a named entry
      rack_df <- study_samples %>% filter(str_ends(pos96, ending))
      rack_samples_list[[paste0("rack", ending, "_samples")]] <- rack_df
      print(paste0("rack", ending, "_samples: ", nrow(rack_df), " rows"))
    }
  } else {
    print("Cannot create racks")
  }
  
  # New: study_racks is the number of racks found
  study_racks <- length(rack_samples_list)
  
  # Based on number of racks found, then size of each rack.
  if(study_racks == 2) {
    print("2 study racks found")
    
    # Default: split each section (before and after cal curve) into two equal chunks
    split1 <- TRUE #split1: split the first half of samples into two sections
    split2 <- TRUE #split2: split the second half of samples into two sections
    
    # Get size of first rack of samples
    first_rack <- rack_samples_list[[1]]
    first_rack_size <- nrow(first_rack)
    
    # If the first rack has less than 60 samples, do it all in one chunk
    if (first_rack_size < 60) {
      print("First rack of samples <60 in size; running in one chunk")
      split1 <- FALSE
      first_half_size <- first_rack_size
    } else if (first_rack_size >= 60) {
      # Otherwise, if the first rack has >= 60 samples,
      first_half_size <- floor(first_rack_size / 2) 
    }
    ####
    
    # Get size of second rack of samples
    second_rack <- rack_samples_list[[2]]
    second_rack_size <- nrow(second_rack)
    
    # If the second rack has less than 60 samples, do it all in one chunk
    if(second_rack_size < 60) {
      print("Second rack of samples <60 in size; running in one chunk")
      split2 <- FALSE
      second_half_size <- second_rack_size
    } else if (second_rack_size >= 60) {
      # Otherwise, if the second rack has >= 60 samples,
      second_half_size <- floor(second_rack_size / 2) #40
    }
    
    ##################### If there is only one study rack:
  } else if (study_racks == 1) {
    print("Only 1 study rack found")
    split1 <-TRUE # default: split the one rack into two sections
    
    first_rack <- rack_samples_list[[1]]
    first_rack_size <- nrow(first_rack)
    
    # If the rack has less than 60 samples, do it all in one chunk
    if(first_rack_size < 60) {
      print("Rack is <60 samples in size; running in one chunk")
      split1 <- FALSE
      first_half_size <- first_rack_size
    } else if (first_rack_size >= 60) {
      #Otherwise, if the rack has >= 60 samples,
      first_half_size <- floor(first_rack_size / 2) 
      second_half_size <- first_rack_size - first_half_size
    }
    
  } else if (study_racks == 0) { 
    print("No study racks found in grouping process.")
  } else if (study_racks == 3) {
    print("3 study racks found. Not coded yet!")
  }
  
  
  ## CREATE LINES BY SAMPLE TYPE ############################################
  ############## BLANKS lines 
  
  # For now: 4 blanks 
  # 2 at the beginning and end labeled 'Blank' 
  # 2 surrounding the Cal Curve labeled 'Cal_Std'
  
  num_blanks <- 4 # 4 blanks
  # Vector for storing lines
  blank_lines_pos <- vector("character", num_blanks)
  blank_lines_neg <- vector("character", num_blanks)
  
  # REAL BLANKS 
  first_blank_line_pos <- paste(
    sample_type,          # Field 1: Sample Type 
    filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
    paste0("Instrument_Blank_", batch,"_0", 1, "_1"),   # Field 3: Sample_ID_ID
    comment,              # Field 4: Comment
    l2,                   # Field 5: L2 Client
    path,                 # Field 6: Path
    reg_pos,           # Field 7: Instrument Method
    paste0("Y:A3"), # Field 8: Position: FIXED for blanks
    "0",                    # Field 9: Inj Vol
    l1,            # Field 10: L1 Study
    l3,                     # Field 11: L3 Laboratory
    "Blank",                # Field 12: Sample Name 
    sep = ","
  )
  
  blank_lines_pos[1] <- first_blank_line_pos
  
  first_blank_line_neg <- paste(
    sample_type,          # Field 1: Sample Type
    filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
    paste0("Instrument_Blank_", batch, "_0", 1, "_2"), # Field 3: Sample_ID_ID
    comment,              # Field 4: Comment
    l2,                   # Field 5: L2 Client
    path,                 # Field 6: Path
    reg_neg,           # Field 7: Instrument Method
    paste0("Y:A3"), # Field 8: Position: FIXED for blank
    "0",                    # Field 9: Inj Vol
    l1,            # Field 10: L1 Study
    l3,                     # Field 11: L3 Laboratory
    "Blank",                # Field 12: Sample Name 
    sep = ","
  )
  
  blank_lines_neg[1] <- first_blank_line_neg
  
  last_blank_line_pos <- paste(
    sample_type,          # Field 1: Sample Type 
    filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
    paste0("Instrument_Blank_", batch,"_0", num_blanks, "_1"),   # Field 3: Sample_ID_ID
    comment,              # Field 4: Comment
    l2,                   # Field 5: L2 Client
    path,                 # Field 6: Path
    reg_pos,           # Field 7: Instrument Method
    paste0("Y:A3"), # Field 8: Position: FIXED for blanks
    "0",                    # Field 9: Inj Vol
    l1,            # Field 10: L1 Study
    l3,                     # Field 11: L3 Laboratory
    "Blank",                # Field 12: Sample Name 
    sep = ","
  )
  
  blank_lines_pos[num_blanks] <- last_blank_line_pos
  
  last_blank_line_neg <- paste(
    sample_type,          # Field 1: Sample Type
    filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
    paste0("Instrument_Blank_", batch, "_0", num_blanks, "_2"), # Field 3: Sample_ID_ID
    comment,              # Field 4: Comment
    l2,                   # Field 5: L2 Client
    path,                 # Field 6: Path
    reg_neg,           # Field 7: Instrument Method
    paste0("Y:A3"), # Field 8: Position: FIXED for blank
    "0",                    # Field 9: Inj Vol
    l1,            # Field 10: L1 Study
    l3,                     # Field 11: L3 Laboratory
    "Blank",                # Field 12: Sample Name 
    sep = ","
  )
  
  blank_lines_neg[num_blanks] <- last_blank_line_neg
  
  # Not real 'BLANKS' Cal_Std - These surround the cal_curve
  for (i in c(2,3)) {
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type 
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0("Instrument_Blank_", batch,"_0", i, "_1"),   # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_pos,           # Field 7: Instrument Method
      paste0("Y:A3"), # Field 8: Position: FIXED for blanks
      "0",                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "Cal_Std",                # Field 12: Sample Name #MANUALLY CHANGE FIRST AND LAST TO BLANK!
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0("Instrument_Blank_", batch, "_0", i, "_2"), # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_neg,           # Field 7: Instrument Method
      paste0("Y:A3"), # Field 8: Position: FIXED for blank
      "0",                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "Cal_Std",                # Field 12: Sample Name #MANUALLY CHANGE FIRST AND LAST TO BLANK!
      sep = ","
    )
    blank_lines_pos[i] <- pos_line
    blank_lines_neg[i] <- neg_line
  }
  
  ############## WATER lines 
  
  # Vector for storing lines
  water_lines_pos <- vector("character", nrow(waters))
  water_lines_neg <- vector("character", nrow(waters))
  
  for (i in 1:nrow(waters)) { # should be 2
    
    # Needed information from data
    sample_id <- waters$Sample_ID[i]
    pos384 <- waters$pos384[i]
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_0", i, "_1"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_pos,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      pos_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "Water",                # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_0", i, "_2"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_neg,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      neg_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "Water",                # Field 12: Sample Name
      sep = ","
    )
    water_lines_pos[i] <- pos_line
    water_lines_neg[i] <- neg_line
  }
  
  ############## NIST lines
  
  # 7/28: MAKE OPTIONAL 
  if (nist_count == 0) {
    run_nist <- FALSE
  } else { # If nist_count > 0, execute the lines
    
    run_nist <- TRUE # assign this for later
    
    # Vector for storing lines
    nist_lines_pos <- vector("character", nrow(nists))
    nist_lines_neg <- vector("character", nrow(nists))
    
    for (i in 1:nrow(nists)) { #usually there will only be 1
      # Needed information from data
      sample_id <- nists$Sample_ID[i]
      pos384 <- nists$pos384[i]
      
      # For each well, create a positive and negative row
      pos_line <- paste(
        sample_type,          # Field 1: Sample Type
        filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
        paste0(sample_id, "_", batch, "_1"),          # Field 3: Sample_ID_ID
        comment,              # Field 4: Comment
        l2,                   # Field 5: L2 Client
        path,                 # Field 6: Path
        reg_pos,           # Field 7: Instrument Method
        paste0(position, pos384), # Field 8: Position  
        pos_vol,                    # Field 9: Inj Vol
        l1,            # Field 10: L1 Study
        l3,                     # Field 11: L3 Laboratory
        "NIST",                # Field 12: Sample Name
        sep = ","
      )
      
      neg_line <- paste(
        sample_type,          # Field 1: Sample Type
        filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
        paste0(sample_id, "_", batch, "_2"),          # Field 3: Sample_ID_ID
        comment,              # Field 4: Comment
        l2,                   # Field 5: L2 Client
        path,                 # Field 6: Path
        reg_neg,           # Field 7: Instrument Method
        paste0(position, pos384), # Field 8: Position  
        neg_vol,                    # Field 9: Inj Vol
        l1,            # Field 10: L1 Study
        l3,                     # Field 11: L3 Laboratory
        "NIST",                # Field 12: Sample Name
        sep = ","
      )
      nist_lines_pos[i] <- pos_line
      nist_lines_neg[i] <- neg_line
    }
    
  } # END ELSE
  
  ############## AMAP lines
  
  # 9/24: MAKE OPTIONAL 
  if (amap_count == 0) {
    run_amap <- FALSE
  } else { # If nist_count > 0, execute the lines
    
    run_amap <- TRUE # assign this for later
  
    # Vector for storing lines
    amap_lines_pos <- vector("character", nrow(amaps))
    amap_lines_neg <- vector("character", nrow(amaps))
    
    for (i in 1:nrow(amaps)) { # should be only 1 after August 2025. Maybe 0 (optional)
      
      # Needed information from data
      sample_id <- amaps$Sample_ID[i]
      pos384 <- amaps$pos384[i]
      
      # For each well, create a positive and negative row
      pos_line <- paste(
        sample_type,          # Field 1: Sample Type
        filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
        paste0(sample_id, "_", batch, "_0", i, "_1"),          # Field 3: Sample_ID_ID
        comment,              # Field 4: Comment
        l2,                   # Field 5: L2 Client
        path,                 # Field 6: Path
        reg_pos,           # Field 7: Instrument Method
        paste0(position, pos384), # Field 8: Position  
        pos_vol,                    # Field 9: Inj Vol
        l1,            # Field 10: L1 Study
        l3,                     # Field 11: L3 Laboratory
        "AMAP",                # Field 12: Sample Name
        sep = ","
      )
      
      neg_line <- paste(
        sample_type,          # Field 1: Sample Type
        filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
        paste0(sample_id, "_", batch, "_0", i, "_2"),          # Field 3: Sample_ID_ID
        comment,              # Field 4: Comment
        l2,                   # Field 5: L2 Client
        path,                 # Field 6: Path
        reg_neg,           # Field 7: Instrument Method
        paste0(position, pos384), # Field 8: Position  
        neg_vol,                    # Field 9: Inj Vol
        l1,            # Field 10: L1 Study
        l3,                     # Field 11: L3 Laboratory
        "AMAP",                # Field 12: Sample Name
        sep = ","
      )
      amap_lines_pos[i] <- pos_line
      amap_lines_neg[i] <- neg_line
    }
  }
  
  ############## POOL lines 
  
  # Create the full run order vector
  run_order <- sprintf("%02d", 1:pool_count) #1:total number of pools (e.g. 12)
  
  # Split the run order into two halves
  half <- pool_count / 2
  pools1$runorder <- run_order[1:half] # 1:half (e.g. 1:6)
  pools2$runorder <- run_order[1:half]
  
  # Check for 12 pools
  if (pool_count == 12) {
    print("Found 12 pools")
  } 
  
  # Check for 20 pools
  if (pool_count == 20) {
    print("Found 20 pools")
  } 
  
  ############## POOL 1
  
  # Vector for storing lines
  pool1_lines_pos <- vector("character", nrow(pools1)) 
  pool1_lines_neg <- vector("character", nrow(pools1))
  
  for (i in 1:nrow(pools1)) {
    # Needed information from data
    sample_id <- pools1$Sample_ID[i]
    pos384 <- pools1$pos384[i]
    order <- pools1$runorder[i]
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_", order, "_1"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_pos,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      pos_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "HRE_Pool",                # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_", order, "_2"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_neg,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      neg_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "HRE_Pool",                # Field 12: Sample Name
      sep = ","
    )
    pool1_lines_pos[i] <- pos_line
    pool1_lines_neg[i] <- neg_line
  }
  
  ############## POOL 2 
  
  # Vector for storing lines
  pool2_lines_pos <- vector("character", nrow(pools2)) 
  pool2_lines_neg <- vector("character", nrow(pools2))
  
  for (i in 1:nrow(pools1)) {
    # Needed information from data
    sample_id <- pools2$Sample_ID[i]
    pos384 <- pools2$pos384[i]
    order <- pools2$runorder[i]
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_", order, "_1"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_pos,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      pos_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "HRE_Pool",                # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_", order, "_2"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_neg,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      neg_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "HRE_Pool",                # Field 12: Sample Name
      sep = ","
    )
    pool2_lines_pos[i] <- pos_line
    pool2_lines_neg[i] <- neg_line
  }
  
  
  #### IF FIRST/LAST BATCH / HRE MS@ BUTTON CLICKED: 
  
  if (hre_ms2) {
    print("Including MSMS on the first HRE pools")
  # generate ms2 lines for the first pools in the run list
    
    ############## POOL 1
    
    # Vector for storing lines
    msms_pool1_lines_pos <- vector("character", 1) # only one of each MSMS for pool 1
    msms_pool1_lines_neg <- vector("character", 1)
    
    i = 1
    sample_id <- pools1$Sample_ID[i]
    pos384 <- pools1$pos384[i]
    order <- pools1$runorder[i]
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_", order, "_1_HRE-MSMS"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      ms2path,                 # Field 6: Path
      ms2_pool_pos,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      pos_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "MSMS",                # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_", order, "_2_HRE-MSMS"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      ms2path,                 # Field 6: Path
      ms2_pool_neg,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      neg_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "MSMS",                # Field 12: Sample Name
      sep = ","
    )
    msms_pool1_lines_pos[i] <- pos_line
    msms_pool1_lines_neg[i] <- neg_line
    
    ############## POOL 2 
    
    # Vector for storing lines
    msms_pool2_lines_pos <- vector("character", 1) # only one of each MSMS for pool 2
    msms_pool2_lines_neg <- vector("character", 1)
    
    i = 1
    sample_id <- pools2$Sample_ID[i]
    pos384 <- pools2$pos384[i]
    order <- pools2$runorder[i]
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_", order, "_1_HRE-MSMS"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      ms2path,                 # Field 6: Path
      ms2_pool_pos,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      pos_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "MSMS",                # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_", order, "_2_HRE-MSMS"),          # Field 3: Sample_ID_ID 
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      ms2path,                 # Field 6: Path
      ms2_pool_neg,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      neg_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "MSMS",                # Field 12: Sample Name
      sep = ","
    )
    msms_pool2_lines_pos[i] <- pos_line
    msms_pool2_lines_neg[i] <- neg_line
    
  } # end HRE MSMS lines
  
  
  ############## Cal Curve lines
  
  # Vector for storing lines
  cal_curve_lines_pos <- vector("character", nrow(cal_curve_big)) #cal_curve_lines_pos is chr [1:8]
  cal_curve_lines_neg <- vector("character", nrow(cal_curve_big))
  
  for (i in 1:nrow(cal_curve_big)) { # should be 8!
    # Needed information from data
    sample_id <- cal_curve_big$Sample_ID[i]
    pos384 <- cal_curve_big$pos384[i]
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_1"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_pos,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      pos_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "Cal_Std",                # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_2"),        # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_neg,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      neg_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "Cal_Std",                # Field 12: Sample Name
      sep = ","
    )
    cal_curve_lines_pos[i] <- pos_line
    cal_curve_lines_neg[i] <- neg_line
  }
  
  ############## PFAS Baby Cal Curve lines with extra cal curve tubes! #################
  
  cal_curve_little_lines_pos <- list()
  cal_curve_little_lines_neg <- list()
  
  # Loop over each data frame in the list. There should be 3 items in the list, each with 2 rows
  for (j in seq_along(cal_curve_little_list)) {
    conc <- cal_curve_little_list[[j]] # 1, 2, 3
    
    # Preallocate character vectors for this small df (always 2 rows)
    pos_lines <- character(nrow(conc))
    neg_lines <- character(nrow(conc))
    
    for (i in 1:nrow(conc)) { # should be 2 rows for each
      sample_id <- conc$Sample_ID[i]
      pos384    <- conc$pos384[i]
      
      # Build the positive line
      pos_lines[i] <- paste(
        sample_type,
        filename_pos,
        paste0(sample_id, "_", batch, "_0", i, "_1"),
        comment,
        l2,
        path,
        reg_pos,
        paste0(position, pos384),
        pos_vol,
        l1,
        l3,
        "Cal_Std",
        sep = ","
      )
      
      # Build the negative line
      neg_lines[i] <- paste(
        sample_type,
        filename_neg,
        paste0(sample_id, "_", batch, "_0", i, "_2"),
        comment,
        l2,
        path,
        reg_neg,
        paste0(position, pos384),
        neg_vol,
        l1,
        l3,
        "Cal_Std",
        sep = ","
      )
    }
    
    # Store lines in the output lists
    cal_curve_little_lines_pos[[j]] <- pos_lines
    cal_curve_little_lines_neg[[j]] <- neg_lines # a list of 3 character vectors each with 2 lines.
  }
  
  ############## PFAS QAQC (standalone) lines added 9/24
  pfas_qaqc_lines_pos <- vector("character", nrow(pfas_qaqcs))
  pfas_qaqc_lines_neg <- vector("character", nrow(pfas_qaqcs))
  
  for (i in 1:nrow(pfas_qaqcs)) {
    
    # Needed information from data
    sample_id <- pfas_qaqcs$Sample_ID[i]
    pos384 <- pfas_qaqcs$pos384[i]
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_0", i, "_1"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_pos,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      pos_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "PFAS_QAQC",                # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_", batch, "_0", i, "_2"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_neg,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      neg_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "PFAS_QAQC",                # Field 12: Sample Name
      sep = ","
    )
    pfas_qaqc_lines_pos[i] <- pos_line
    pfas_qaqc_lines_neg[i] <- neg_line
    
    
  }
  
  ############## SAMPLE LINES
  
  # Vector for storing lines
  study_sample_lines_pos <- vector("character", nrow(study_samples))
  study_sample_lines_neg <- vector("character", nrow(study_samples))
  
  for (i in 1:nrow(study_samples)) {
    
    # Needed information from data
    sample_id <- study_samples$Sample_ID[i]
    pos384 <- study_samples$pos384[i]
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_pos,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_1"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_pos,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      pos_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "Study_Sample",                # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,          # Field 1: Sample Type
      filename_neg,             # Field 2: File Name NEEDS ORDER NUMBER when printing.
      paste0(sample_id, "_2"),          # Field 3: Sample_ID_ID
      comment,              # Field 4: Comment
      l2,                   # Field 5: L2 Client
      path,                 # Field 6: Path
      reg_neg,           # Field 7: Instrument Method
      paste0(position, pos384), # Field 8: Position  
      neg_vol,                    # Field 9: Inj Vol
      l1,            # Field 10: L1 Study
      l3,                     # Field 11: L3 Laboratory
      "Study_Sample",                # Field 12: Sample Name
      sep = ","
    )
    study_sample_lines_pos[i] <- pos_line
    study_sample_lines_neg[i] <- neg_line
  }
  
  
  ############## MSMS Lines
  
  # First/Last batch: Special MSMS on HRE_Pool (code later)
  # PFAS-MSMS 6 times
  # non-PFAS MSMS 6 times
  
  ########## CHOOSE POSITIONS RANDOMLY - MUST BE SAMPLE POSITIONS
  
  # RANDOMLY SELECT LOCATIONS OUR OF THOSE THAT EXIST
  locations <- final_data %>%
    filter(!is.na(Sample_ID)) %>%
    filter(sampletype == 'Study_Sample') %>%
    select(pos384)
  
  # 'locations' are the 384-wp positions of STUDY SAMPLES ONLY
  all_locations <- locations %>% pull(pos384)
  
  # Randomly sample 6 PFAS MS2 positions
  pfas_ms2_positions <- sample(all_locations, 6)
  
  # Remove already-sampled positions from the pool
  remaining_locations <- setdiff(all_locations, pfas_ms2_positions)
  
  # Randomly sample 6 non-PFAS MS2 positions
  nonpfas_ms2_positions <- sample(remaining_locations, 6)
  
  ##
  
  # Add a marker to know whether the study sample is an MSMS position
  study_samples$pfms <- FALSE
  rows <- which(study_samples$pos384 %in% pfas_ms2_positions)
  study_samples$pfms[rows] <- TRUE
  
  study_samples$nonpfms <- FALSE
  rows <- which(study_samples$pos384 %in% nonpfas_ms2_positions)
  study_samples$nonpfms[rows] <- TRUE
  
  ############## PFAS MSMS LINES
  
  # Vector for storing lines
  pfas_msms_lines_pos <- vector("character", 6)
  pfas_msms_lines_neg <- vector("character", 6)
  
  for (i in 1:6) {
    pos384 <- pfas_ms2_positions[i]
    
    # find matrixID for this position from study_samples
    row <- which(study_samples$pos384 == pos384)
    sample_id <- study_samples$Sample_ID[row] # FIXED BATCH 5 10/31

    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,
      # Field 1: Sample Type
      filename_pos,
      # Field 2: File Name NEEDS ORDER NUMBER AND PFAS-MSMS AT END
      paste0(sample_id, "_1_PFAS-MSMS"),
      # Field 3: Sample_ID_ID
      comment,
      # Field 4: Comment
      l2,
      # Field 5: L2 Client
      ms2path,
      # Field 6: Path
      ms2_pfas_pos,
      # Field 7: Instrument Method
      paste0(position, pos384),
      # Field 8: Position
      pos_vol,
      # Field 9: Inj Vol
      l1,
      # Field 10: L1 Study
      l3,
      # Field 11: L3 Laboratory
      "PFAS-MSMS",
      # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,
      # Field 1: Sample Type
      filename_neg,
      # Field 2: File Name NEEDS ORDER NUMBER AND PFAS-MSMS AT END
      paste0(sample_id, "_2_PFAS-MSMS"),
      # Field 3: Sample_ID_ID
      comment,
      # Field 4: Comment
      l2,
      # Field 5: L2 Client
      ms2path,
      # Field 6: Path
      ms2_pfas_neg,
      # Field 7: Instrument Method
      paste0(position, pos384),
      # Field 8: Position
      neg_vol,
      # Field 9: Inj Vol
      l1,
      # Field 10: L1 Study
      l3,
      # Field 11: L3 Laboratory
      "PFAS-MSMS",
      # Field 12: Sample Name
      sep = ","
    )
    pfas_msms_lines_pos[i] <- pos_line
    pfas_msms_lines_neg[i] <- neg_line
  }
  
  ############## Non-PFAS MSMS LINES
  
  # Vector for storing lines
  nonpfas_msms_lines_pos <- vector("character", 6)
  nonpfas_msms_lines_neg <- vector("character", 6)
  
  for (i in 1:6) {
    pos384 <- nonpfas_ms2_positions[i]
    # find matrix ID for this position from study_samples
    row <- which(study_samples$pos384 == pos384)
    sample_id <- study_samples$Sample_ID[row] # FIXED BATCH 5 10/31
    
    # For each well, create a positive and negative row
    pos_line <- paste(
      sample_type,
      # Field 1: Sample Type
      filename_pos,
      # Field 2: File Name NEEDS ORDER NUMBER AND _MSMS AT END
      paste0(sample_id, "_1_MSMS"),
      # Field 3: Sample_ID_ID
      comment,
      # Field 4: Comment
      l2,
      # Field 5: L2 Client
      ms2path,
      # Field 6: Path
      ms2_nonpfas_pos,
      # Field 7: Instrument Method
      paste0(position, pos384),
      # Field 8: Position
      pos_vol,
      # Field 9: Inj Vol
      l1,
      # Field 10: L1 Study
      l3,
      # Field 11: L3 Laboratory
      "MSMS",
      # Field 12: Sample Name
      sep = ","
    )
    
    neg_line <- paste(
      sample_type,
      # Field 1: Sample Type
      filename_neg,
      # Field 2: File Name NEEDS ORDER NUMBER AND _MSMS AT END
      paste0(sample_id, "_2_MSMS"),
      # Field 3: Sample_ID_ID
      comment,
      # Field 4: Comment
      l2,
      # Field 5: L2 Client
      ms2path,
      # Field 6: Path
      ms2_nonpfas_neg,
      # Field 7: Instrument Method
      paste0(position, pos384),
      # Field 8: Position
      neg_vol,
      # Field 9: Inj Vol
      l1,
      # Field 10: L1 Study
      l3,
      # Field 11: L3 Laboratory
      "MSMS",
      # Field 12: Sample Name
      sep = ","
    )
    nonpfas_msms_lines_pos[i] <- pos_line
    nonpfas_msms_lines_neg[i] <- neg_line
  }
  
  # Functions to help modifying as we write lines ######################################
  # MODIFY Function:
  # appends run order to the end of the file name
  # appends rack number based on position (first or second half)
  # appends MSMS-specific suffixes
  
  total_runs <- total_count #total number of rows in the final dataframe
  
  modify <- function(line, run_order, msms_type = NULL) {
    # Split the line by commas
    parts <- strsplit(line, ",")[[1]]
    
    # Format run order as a 3-digit string
    formatted_run_order <- sprintf("%03d", run_order)
    
    # First append the run order to field 2 (filename)
    parts[2] <- paste0(parts[2], formatted_run_order)
    
    # If this is an MSMS run, append the appropriate suffix
    if (!is.null(msms_type)) {
      if (msms_type == "PFAS") {
        parts[2] <- paste0(parts[2], "_PFAS-MSMS")
      } else if (msms_type == "nonPFAS") {
        parts[2] <- paste0(parts[2], "_MSMS")
      } else if (msms_type == "HRE_pool") {
      parts[2] <- paste0(parts[2], "_HRE-MSMS")
      }
    }
    
    ## TODO - hardcoded number below --------------
    
    # Choose the appropriate l2 value 
    if (run_order > first_rack_size + 21 ) { # 21 = half QAQC 
      l2_value <- rack2
    } else {
      l2_value <- rack1
    }
    
    # Update L2 field (assumed to be in position 5)
    parts[5] <- l2_value
    
    # Rejoin the parts with commas
    paste(parts, collapse = ",")
  } # END MODIFY FUNCTION
  
  ##### WRITE FILE ##########################################################################################
  
  ## INITIALIZE
  # Create a connection to the file
  file_conn <- file(sequence_filepath, "w") #from shiny
  # "w" to overwrite or create, "a" to append
  
  #####################################################################################################################################################################################
  # START WRITING
  #####################################################################################################################################################################################
  run_order <- 1
  
  # Headers
  # Write the two-row header format to the file
  writeLines("Bracket Type=4,,,,,,,,,,,", file_conn)
  writeLines(
    "Sample Type,File Name,Sample ID,Comment,L2 Client,Path,Instrument Method,Position,Inj Vol,L1 Study,L3 Laboratory,Sample Name",
    file_conn
  )
  
  # 1 instrument blank - actual blank
  writeLines(modify(blank_lines_pos[1], run_order), file_conn)
  writeLines(modify(blank_lines_neg[1], run_order), file_conn)
  run_order <- run_order + 1
  
  # 1 water blank - 1 of 2
  writeLines(modify(water_lines_pos[1], run_order), file_conn)
  writeLines(modify(water_lines_neg[1], run_order), file_conn)
  run_order <- run_order + 1
  
  # 1 NIST - 7/29 changed to OPTIONAL
  if (run_nist) {
    # only execute if there is a NIST sample
    writeLines(modify(nist_lines_pos[1], run_order), file_conn)
    writeLines(modify(nist_lines_neg[1], run_order), file_conn)
    run_order <- run_order + 1
  } else {
    print("No NIST sample identified in batch.\n")
  }
  
  # 1 AMAP - changed to optional 9/24
  if (run_amap) {
    #only execute if there is an AMAP
    writeLines(modify(amap_lines_pos[1], run_order), file_conn)
    writeLines(modify(amap_lines_neg[1], run_order), file_conn)
    run_order <- run_order + 1
  }else {
    print("No AMAP sample identified in batch.\n")
  }
  
  ## 3 PFAS BABY CAL CURVE (1 of 2)
  # Loop over each calibration point group
  for (i in seq_along(cal_curve_little_lines_pos)) {
    writeLines(modify(cal_curve_little_lines_pos[[i]][1], run_order), file_conn)
    writeLines(modify(cal_curve_little_lines_neg[[i]][1], run_order), file_conn)
    run_order <- run_order + 1
  }
  
  ## PFAS QAQC (1/3)
  pfas_qaqc_tally <- 1
  writeLines(modify(pfas_qaqc_lines_pos[pfas_qaqc_tally], run_order), file_conn)
  writeLines(modify(pfas_qaqc_lines_neg[pfas_qaqc_tally], run_order), file_conn)
  run_order <- run_order + 1
  pfas_qaqc_tally <- pfas_qaqc_tally + 1
  
  ####### POOL ##########################################
  # separated by pool number 5/29
  # Pool 1 out of 6 for expected for full batch - always runs 
  
  each_final_pool_count <- nrow(pool1_lines_pos) # for counting - TODO?
  pool_tally <- 1
  
  ## POOL 1
  writeLines(modify(pool1_lines_pos[pool_tally], run_order), file_conn) # Pool 1
  writeLines(modify(pool1_lines_neg[pool_tally], run_order), file_conn)
  ## IF RUNNING HRE-MSMS: 
  if (hre_ms2) {
    writeLines(modify(msms_pool1_lines_pos[1], run_order, msms_type = "HRE_pool"),file_conn)
    writeLines(modify(msms_pool1_lines_neg[1], run_order, msms_type = "HRE_pool"),file_conn)
  }
  run_order <- run_order + 1
  
  ## POOL 2
  writeLines(modify(pool2_lines_pos[pool_tally], run_order), file_conn) # Pool 2
  writeLines(modify(pool2_lines_neg[pool_tally], run_order), file_conn)
  
  ## IF RUNNING HRE-MSMS: 
  if (hre_ms2) {
    writeLines(modify(msms_pool2_lines_pos[1], run_order, msms_type = "HRE_pool"),file_conn)
    writeLines(modify(msms_pool2_lines_neg[1], run_order, msms_type = "HRE_pool"),file_conn)
  }
  run_order <- run_order + 1
  
  pool_tally <- pool_tally + 1 
  
  ### Note: MSMS LOGIC ###############################
  # When writing study samples, if
  
  # study_samples$pfms == TRUE
  # then there is a PFAS MSMS run after that sample
  # study_samples$nonpfms == TRUE
  # then there is a nonPFAS MSMS run after that sample.
  
  ## Sample size logic: 7/29
  
  # if study_racks == 2 or 1
  # if 2, split = c(T/F, T/F)
  # if 1, split = T/F
  
  ## 7/28, 7/29 NEW: 1 of 4 groups of samples
  
  for (i in 1:first_half_size) { #This will always run. 
    
    # If first half is not split (<60 samples) first_half_size is the whole chunk
    # If first half is split (>= 60 samples), first_half_size is HALF the first rack
    
    writeLines(modify(study_sample_lines_pos[i], run_order), file_conn)
    writeLines(modify(study_sample_lines_neg[i], run_order), file_conn)
    
    # If this sample is flagged for PFAS MSMS, add those lines
    if (study_samples$pfms[i] == TRUE) {
      # Find which position in the pfas_ms2_positions list this sample corresponds to
      pos_index <-
        which(pfas_ms2_positions == study_samples$pos384[i])
      
      writeLines(modify(pfas_msms_lines_pos[pos_index], run_order, msms_type = "PFAS"),
                 file_conn)
      writeLines(modify(pfas_msms_lines_neg[pos_index], run_order, msms_type = "PFAS"),
                 file_conn)
    }
    
    # Same for non-PFAS MSMS
    if (study_samples$nonpfms[i] == TRUE) {
      # Find which position in the pfas_ms2_positions list this sample corresponds to
      pos_index <-
        which(nonpfas_ms2_positions == study_samples$pos384[i])
      
      writeLines(modify(nonpfas_msms_lines_pos[pos_index], run_order, msms_type = "nonPFAS"),
                 file_conn)
      writeLines(modify(nonpfas_msms_lines_neg[pos_index], run_order, msms_type = "nonPFAS"),
                 file_conn)
    }
    #Increment
    run_order <- run_order + 1
  }
  ################################################################################## End study sample chunk 1 of 4
  
  # Pool 2 out of 6 for expected for full batch - always runs
  writeLines(modify(pool1_lines_pos[pool_tally], run_order), file_conn) # Pool 1
  writeLines(modify(pool1_lines_neg[pool_tally], run_order), file_conn)
  run_order <- run_order + 1
  
  writeLines(modify(pool2_lines_pos[pool_tally], run_order), file_conn) # Pool 2
  writeLines(modify(pool2_lines_neg[pool_tally], run_order), file_conn)
  run_order <- run_order + 1
  pool_tally <- pool_tally + 1
  
  # If <60 samples in the first rack: SKIP BELOW until the 1st PFAS curve
  
  if (split1) {
    for (i in ((first_half_size + 1):(first_rack_size))) { #changed 8/27
      
      writeLines(modify(study_sample_lines_pos[i], run_order), file_conn)
      writeLines(modify(study_sample_lines_neg[i], run_order), file_conn)
      
      # If this sample is flagged for PFAS MSMS, add those lines
      if (study_samples$pfms[i] == TRUE) {
        # Find which position in the pfas_ms2_positions list this sample corresponds to
        pos_index <-
          which(pfas_ms2_positions == study_samples$pos384[i])
        
        writeLines(modify(pfas_msms_lines_pos[pos_index], run_order, msms_type = "PFAS"),
                   file_conn)
        writeLines(modify(pfas_msms_lines_neg[pos_index], run_order, msms_type = "PFAS"),
                   file_conn)
      }
      
      # Same for non-PFAS MSMS
      if (study_samples$nonpfms[i] == TRUE) {
        # Find which position in the pfas_ms2_positions list this sample corresponds to
        pos_index <-
          which(nonpfas_ms2_positions == study_samples$pos384[i])
        
        writeLines(modify(nonpfas_msms_lines_pos[pos_index], run_order, msms_type = "nonPFAS"),
                   file_conn)
        writeLines(modify(nonpfas_msms_lines_neg[pos_index], run_order, msms_type = "nonPFAS"),
                   file_conn)
      }
      run_order <- run_order + 1
    }
    ################################################################################## End study sample chunk 2 of 4
    
    # Pool 3 out of 6 for expected for full batch - only runs if two chunks in first part
    writeLines(modify(pool1_lines_pos[pool_tally], run_order), file_conn) # Pool 1
    writeLines(modify(pool1_lines_neg[pool_tally], run_order), file_conn)
    run_order <- run_order + 1
    
    writeLines(modify(pool2_lines_pos[pool_tally], run_order), file_conn) # Pool 2
    writeLines(modify(pool2_lines_neg[pool_tally], run_order), file_conn)
    run_order <- run_order + 1
    pool_tally <- pool_tally + 1
    
  } # RESUME if only one chunk of samples in first part (split1 == FALSE) 
  
  ################################################################################
  
  ## PFAS QAQC (2/3)
  if (study_racks == 2) {
    writeLines(modify(pfas_qaqc_lines_pos[pfas_qaqc_tally], run_order), file_conn)
    writeLines(modify(pfas_qaqc_lines_neg[pfas_qaqc_tally], run_order), file_conn)
    run_order <- run_order + 1
    pfas_qaqc_tally <- pfas_qaqc_tally + 1
  }
  
  ################################################################
  
  # # 1 instrument blank - before Cal Curve
  writeLines(modify(blank_lines_pos[2], run_order), file_conn)
  writeLines(modify(blank_lines_neg[2], run_order), file_conn)
  run_order <- run_order + 1
  
  # CAL CURVE !!!! # changed to loop 5/29
  for (i in 1:length(cal_curve_lines_pos)) {
    # should be 8
    writeLines(modify(cal_curve_lines_pos[i], run_order), file_conn)
    writeLines(modify(cal_curve_lines_neg[i], run_order), file_conn)
    run_order <- run_order + 1
  }
  
  # 1 instrument blank - after cal curve
  writeLines(modify(blank_lines_pos[3], run_order), file_conn)
  writeLines(modify(blank_lines_neg[3], run_order), file_conn)
  run_order <- run_order + 1
  
  ################################################################################
  
  # ONLY RUN IF THERE ARE TWO STUDY RACKS
  # Otherwise, skip to 3rd PFAS curve.
  
  if (study_racks == 2) {
    
    # Pool 4 out of 6 for expected for full batch - only runs if there are two sample racks
    writeLines(modify(pool1_lines_pos[pool_tally], run_order), file_conn) # Pool 1
    writeLines(modify(pool1_lines_neg[pool_tally], run_order), file_conn)
    run_order <- run_order + 1
    
    writeLines(modify(pool2_lines_pos[pool_tally], run_order), file_conn) # Pool 2
    writeLines(modify(pool2_lines_neg[pool_tally], run_order), file_conn)
    run_order <- run_order + 1
    pool_tally <- pool_tally + 1
    
    # 3 of 4 groups of study samples ######################################
    for (i in ((first_rack_size + 1):(first_rack_size + second_half_size))) {
      
      # If second half is not split (<60 samples) second_half_size is the whole chunk
      # If second half is split (>= 60 samples), second_half_size is HALF the first rack
      
      writeLines(modify(study_sample_lines_pos[i], run_order), file_conn)
      writeLines(modify(study_sample_lines_neg[i], run_order), file_conn)
      
      if (i <= nrow(study_samples)) { #safeguard; i might exceed
        # If this sample is flagged for PFAS MSMS, add those lines
        if (study_samples$pfms[i] == TRUE) { #TODO
          # Find which position in the pfas_ms2_positions list this sample corresponds to
          pos_index <-
            which(pfas_ms2_positions == study_samples$pos384[i])
          
          writeLines(modify(pfas_msms_lines_pos[pos_index], run_order, msms_type = "PFAS"),
                     file_conn)
          writeLines(modify(pfas_msms_lines_neg[pos_index], run_order, msms_type = "PFAS"),
                     file_conn)
        }
        # Same for non-PFAS MSMS
        if (study_samples$nonpfms[i] == TRUE) {
          # Find which position in the pfas_ms2_positions list this sample corresponds to
          pos_index <-
            which(nonpfas_ms2_positions == study_samples$pos384[i])
          
          writeLines(modify(nonpfas_msms_lines_pos[pos_index], run_order, msms_type = "nonPFAS"),
                     file_conn)
          writeLines(modify(nonpfas_msms_lines_neg[pos_index], run_order, msms_type = "nonPFAS"),
                     file_conn)
        }
      }
      
      run_order <- run_order + 1
    }
    
    # Pool 5 out of 6 for expected for full batch - only runs if the second chunk has > 60 samples (two chunks)
    writeLines(modify(pool1_lines_pos[pool_tally], run_order), file_conn) # Pool 1
    writeLines(modify(pool1_lines_neg[pool_tally], run_order), file_conn)
    run_order <- run_order + 1
    
    writeLines(modify(pool2_lines_pos[pool_tally], run_order), file_conn) # Pool 2
    writeLines(modify(pool2_lines_neg[pool_tally], run_order), file_conn)
    run_order <- run_order + 1
    pool_tally <- pool_tally + 1
    
    # If <60 samples in the second rack: SKIP this section
    if (split2) {
      
      # Last of 4 groups of samples ##################
      for (i in ((first_rack_size + second_half_size + 1):(study_sample_count))) {
        
        writeLines(modify(study_sample_lines_pos[i], run_order), file_conn)
        writeLines(modify(study_sample_lines_neg[i], run_order), file_conn)
        
        if (i <= nrow(study_samples)) { #safeguard; i might exceed
          
          #If this sample is flagged for PFAS MSMS, add those lines
          if (study_samples$pfms[i] == TRUE) {
            # Find which position in the pfas_ms2_positions list this sample corresponds to
            pos_index <-
              which(pfas_ms2_positions == study_samples$pos384[i])
            
            writeLines(modify(pfas_msms_lines_pos[pos_index], run_order, msms_type = "PFAS"),
                       file_conn)
            writeLines(modify(pfas_msms_lines_neg[pos_index], run_order, msms_type = "PFAS"),
                       file_conn)
          }
          
          # Same for non-PFAS MSMS
          if (study_samples$nonpfms[i] == TRUE) {
            # Find which position in the pfas_ms2_positions list this sample corresponds to
            pos_index <-
              which(nonpfas_ms2_positions == study_samples$pos384[i])
            
            writeLines(modify(nonpfas_msms_lines_pos[pos_index], run_order, msms_type = "nonPFAS"),
                       file_conn)
            writeLines(modify(nonpfas_msms_lines_neg[pos_index], run_order, msms_type = "nonPFAS"),
                       file_conn)
          }
        }
        
        run_order <- run_order + 1
      } # END sample chunk 4 of 4
      
      # Pool 6 out of 6 for expected for full batch - only runs if the second rack > 60 samples
      writeLines(modify(pool1_lines_pos[pool_tally], run_order), file_conn) # Pool 1
      writeLines(modify(pool1_lines_neg[pool_tally], run_order), file_conn)
      run_order <- run_order + 1

      writeLines(modify(pool2_lines_pos[pool_tally], run_order), file_conn) # Pool 2
      writeLines(modify(pool2_lines_neg[pool_tally], run_order), file_conn)
      run_order <- run_order + 1
      
    }  # RESUME if only one study sample chunk for second half (split2 == FALSE)
   
    
    ## 3 PFAS BABY CAL CURVE (2 of 2)
    # Loop over each calibration point group
    for (i in seq_along(cal_curve_little_lines_pos)) {
      writeLines(modify(cal_curve_little_lines_pos[[i]][2], run_order), file_conn)
      writeLines(modify(cal_curve_little_lines_neg[[i]][2], run_order), file_conn)
      run_order <- run_order + 1
    
    } 
  
  } # RESUME if only one study rack 
  
  ## PFAS QAQC (3/3)
  writeLines(modify(pfas_qaqc_lines_pos[pfas_qaqc_tally], run_order), file_conn)
  writeLines(modify(pfas_qaqc_lines_neg[pfas_qaqc_tally], run_order), file_conn)
  run_order <- run_order + 1
  
  # 1 water blank - out of 2
  writeLines(modify(water_lines_pos[2], run_order), file_conn)
  writeLines(modify(water_lines_neg[2], run_order), file_conn)
  run_order <- run_order + 1
  
  # 1 instrument blank - actual blank, num_blanks = 4
  writeLines(modify(blank_lines_pos[num_blanks], run_order), file_conn) #4 blanks
  writeLines(modify(blank_lines_neg[num_blanks], run_order), file_conn)
  #######################################################################################################################
  
  close(file_conn)
  gc() # Force garbage collector helps release lingering file handles
  # So you can open without read-only
  
  return(invisible(TRUE)) # this big function is not meant to return anyting, just generate csv
}