from opentrons import protocol_api
from opentrons import types
from opentrons.protocol_api import COLUMN, ROW, ALL

metadata = {
    'protocolName': 'Protocol#2: Solvent addition (C18 only) and supernatant transfer to two 384WPs for LC analysis.',
    'author': 'Maria Cardelino + Catherine Mullins',
    'description': 'Adds 60 uL water to C18 plate. Then adds 30 uL supernatant to both C18 and HILIC plates for LC analysis.'
}
requirements = {"robotType": "Flex", "apiLevel": "2.20"}


def run(protocol: protocol_api.ProtocolContext):

    # Turn on rail lights
    protocol.set_rail_lights(True)

    #Tell robot where the trashcan is
    trash = protocol.load_trash_bin("D3")

    #### Variable defintions ####################################
    
    ## Variables for solvent dilution
    solvent_vol = 60 # Solvent volume
    airgap = 10 # Airgap for solvent
    Well = 'A1' # Do not change
    
    solvent_blow_rate = 800 #ul/sec 
    solvent_asp_rate_WATER = 40 # ul/sec
    solvent_disp_rate_WATER = 120 # ul/sec 
    solvent_airgap_rate = 15 # ul/sec    
    
    ## Variables for supernatant transfer
    asp_height = 4.5 # Saw protein contamination at 3.75, adjusted up to 4.5 . The protein contamination might have been due to performing a labware position check with a melted plate. 
    blow_height = 12 # Distance in mm ABOVE THE BOTTOM of the 384 wp where the supernatant dispense is performed.
    sample_vol_C18 = 30 # Volume of supernatant for C18 plate(uL)
    sample_vol_HILIC = 40 # Volume of supernatant for HILIC plate(uL)
    airgap_sample = 5  # Airgap size (uL) for supernatant
    
    sup_asp_rate = 5 #ul/sec 
    sup_disp_rate = 10 #ul/sec 
    
    #### Equipment Locations ######################################
    
    ## Location for tips - solvent tips ---
    
    tiprack_200_c18 = protocol.load_labware(
        'opentrons_flex_96_tiprack_200ul', 'C3', 
        adapter='opentrons_flex_96_tiprack_adapter')  # 200 uL tips for C18 
    
    ## Location for tips - sample tips ---

    tiprack_50_1 = protocol.load_labware(
        'opentrons_flex_96_filtertiprack_50ul', 'A1',
        adapter='opentrons_flex_96_tiprack_adapter')  # 50 uL tips - only one location for now - change out at C3.     

    tiprack_50_2 = protocol.load_labware(
        'opentrons_flex_96_filtertiprack_50ul', 'A2',
        adapter='opentrons_flex_96_tiprack_adapter')  # 50 uL tips - only one location for now - change out at C3.    


    tiprack_50_3 = protocol.load_labware(
        'opentrons_flex_96_filtertiprack_50ul', 'A3',
        adapter='opentrons_flex_96_tiprack_adapter')  # 50 uL tips - only one location for now - change out at C3.             
           
    tiprack_50_4 = protocol.load_labware(
        'opentrons_flex_96_filtertiprack_50ul', 'B3',
        adapter='opentrons_flex_96_tiprack_adapter')  # 50 uL tips - only one location for now - change out at C3.             
       

    ## Location for reservoir
    reservoir_water = protocol.load_labware('nest_1_reservoir_195ml', 'C2') # C18 reservoir
    
    

    ## Location for temperature modules and destination plates    
    temp_module_1 = protocol.load_module('temperature module gen2', 'B1')
    temp_module_1.set_temperature(4)
    hilic_plate = temp_module_1.load_labware('thermofisher_384_wellplate_250ul') # HILIC - update to nunc for sharing!!!

    temp_module_2 = protocol.load_module('temperature module gen2', 'C1')
    temp_module_2.set_temperature(4)
    c18_plate = temp_module_2.load_labware('thermofisher_384_wellplate_250ul') # C18 - update to nunc for sharing!!!

    ## Location for source plate (384 well plate) 
    temp_module_3 = protocol.load_module('temperature module gen2', 'D1')
    temp_module_3.set_temperature(4)
    source_plate = temp_module_3.load_labware('thermofisher_384_wellplate_250ul') 

   
    ##### Load labware: Pipette Configuration 1 ##################################
    pipette = protocol.load_instrument(
        instrument_name="flex_96channel_1000"
    )
          
    
    #### Change to 200 uL tiprack ##################################
    pipette.configure_nozzle_layout(
        style=ALL,
        start="A1",
        tip_racks=[tiprack_200_c18] 
    )

    # Second, transfer water to C18 plate       
    pipette.pick_up_tip(tiprack_200_c18)
    pipette.move_to(reservoir_water["A1"].top(20))
    solvent_addition(pipette, solvent_blow_rate, solvent_asp_rate_WATER, solvent_disp_rate_WATER, solvent_vol, reservoir_water, c18_plate, Well, solvent_airgap_rate, airgap, "A1")

    pipette.move_to(reservoir_water["A1"].top(20), force_direct = True)     
    solvent_addition(pipette, solvent_blow_rate, solvent_asp_rate_WATER, solvent_disp_rate_WATER, solvent_vol, reservoir_water, c18_plate, Well, solvent_airgap_rate, airgap, "A2")

    pipette.move_to(reservoir_water["A1"].top(20), force_direct = True)     
    solvent_addition(pipette, solvent_blow_rate, solvent_asp_rate_WATER, solvent_disp_rate_WATER, solvent_vol, reservoir_water, c18_plate, Well, solvent_airgap_rate, airgap, "B1")
    
    pipette.move_to(reservoir_water["A1"].top(20), force_direct = True)     
    solvent_addition(pipette, solvent_blow_rate, solvent_asp_rate_WATER, solvent_disp_rate_WATER, solvent_vol, reservoir_water, c18_plate, Well, solvent_airgap_rate, airgap, "B2")
    
    #pipette.drop_tip()
    pipette.drop_tip(tiprack_200_c18['A1']) #reuse tips for water   
   
    ### END SOLVENT ADDITION ###############################################
    
    # Pause for user to add source plate
    protocol.pause('End solvent addition. Please place the source 384-well plate in position D1 and remove seal.')

    #### Supernatant Transfer: from 384 well source plate to C18 and HILIC 384 well destination plates ##############################
       
    #### Pipette configuration ###########################
    
    pipette.configure_nozzle_layout(
        style=ALL,
        start="A1", 
        tip_racks=[tiprack_50_1, tiprack_50_2, tiprack_50_3, tiprack_50_4] # 50 uL tips 
    )
         
    #### Supernatant transfer ############################################################################################    
    
    #### FIRST (A1) SUPERNATANT TRANSFER - 96 AT A TIME  ######################################
    
    transfer_supernatant(pipette, source_plate, c18_plate, hilic_plate, tiprack_50_1, sup_asp_rate, sup_disp_rate, sample_vol_C18, sample_vol_HILIC, airgap_sample, blow_height, asp_height, "A1", protocol)
    transfer_supernatant(pipette, source_plate, c18_plate, hilic_plate, tiprack_50_2, sup_asp_rate, sup_disp_rate, sample_vol_C18, sample_vol_HILIC, airgap_sample, blow_height, asp_height, "A2", protocol)
    transfer_supernatant(pipette, source_plate, c18_plate, hilic_plate, tiprack_50_3, sup_asp_rate, sup_disp_rate, sample_vol_C18, sample_vol_HILIC, airgap_sample, blow_height, asp_height, "B1", protocol)
    transfer_supernatant(pipette, source_plate, c18_plate, hilic_plate, tiprack_50_4, sup_asp_rate, sup_disp_rate, sample_vol_C18, sample_vol_HILIC, airgap_sample, blow_height, asp_height, "B2", protocol)

    #### END PROTOCOL SEQUENCE #################################################################################################################################   
    
    #### DEFINITIONS ########################################################
    
    # Supernatant Transfer function - transfers supernant 96 wells at a time from source 384 well plate to destination 384 well plates (2) - C18 and HILIC.                                                                   
def transfer_supernatant(pte, source_plate, c18_plate, hilic_plate, tiprack, sup_asp, sup_disp, svol_C18, svol_HILIC, air, blow, x, well_id, ctx):

    pte.flow_rate.aspirate = sup_asp  
    pte.flow_rate.dispense = sup_disp 
    
    # Pick up a new tip from the 50 uL tip rack
    pte.pick_up_tip(tiprack)
    
    ##### C18 PLATE ##################################
    
    # Aspirate 30 uL supernatant + air from source plate, take to C18 plate
    pte.move_to(source_plate[well_id].top())
    pte.flow_rate.aspirate = 1000  
    pte.aspirate(15)
    pte.move_to(source_plate[well_id].bottom(x), speed = 10)
    pte.flow_rate.aspirate = sup_asp  
    pte.aspirate(svol_C18, source_plate[well_id].bottom(x)) # x = asp_height (3.75 mm) above well bottom.
    pte.move_to(source_plate[well_id].top(5))
    pte.aspirate(air)  # Aspirate air gap to ensure clean transfer


    # Transfer the supernatant to the C18 plate
    pte.move_to(c18_plate[well_id].top(5), force_direct=True)
    pte.dispense(svol_C18 + air, c18_plate[well_id].bottom(blow)) 

    pte.move_to(c18_plate[well_id].bottom(3), speed = 10) # Drop down to release any droplets  
    pte.move_to(c18_plate[well_id].top(-10), speed = 10) # Move back up   
    ctx.delay(2)       
    pte.flow_rate.dispense = 1000
    pte.dispense(14)    

    # Tip touch + blow out
    pte.move_to(c18_plate[well_id].top(-3)) # Move back up
    pte.move_to(c18_plate[well_id].top(-3).move(types.Point(x=1.5)), speed = 8)

    pte.move_to(c18_plate[well_id].top(5).move(types.Point(x=0)))     
   

   #### HILIC PLATE #####################################
    pte.move_to(source_plate[well_id].top(5), force_direct=True)
    pte.flow_rate.aspirate = 1000  
    pte.aspirate(4)
    pte.move_to(source_plate[well_id].bottom(x), speed = 10)
    pte.flow_rate.aspirate = sup_asp 
    pte.aspirate(svol_HILIC, source_plate[well_id].bottom(x)) # x = asp_height (3.75 mm) above well bottom.   
    pte.move_to(source_plate[well_id].top(5))
    pte.aspirate(air)  # Aspirate air gap to ensure clean transfer


    # Transfer the supernatant to the HILIC plate
    pte.move_to(hilic_plate[well_id].top(5), force_direct=True)
    pte.flow_rate.dispense = sup_disp 
    pte.dispense(svol_HILIC + air, hilic_plate[well_id].bottom(blow))  # Dispense the supernatant and air 12 mm from BOTTOM

    pte.move_to(hilic_plate[well_id].bottom(3), speed = 10) # Drop down to release any droplets 
    pte.move_to(hilic_plate[well_id].top(-10), speed = 10) # Move back up    
    ctx.delay(2)       
    pte.flow_rate.dispense = 1000
    pte.dispense(4) 
    
    # Tip touch 
    pte.move_to(hilic_plate[well_id].top(-3)) # Move back up
    pte.move_to(hilic_plate[well_id].top(-3).move(types.Point(x=1.5)), speed = 8)

    pte.move_to(hilic_plate[well_id].top(5).move(types.Point(x=-0)))  
    
    # Finish    
    pte.drop_tip()
    #pte.drop_tip(tiprack['A1']) #reuse tips for testing    
    
    pte.reset_tipracks() 
   
    # ES prewetting function  
def prewet(pte, sol_blow, sol_asp, sol_disp, sol_vol, reservoir, well, air_rate, air, ctx):
    
    pte.flow_rate.blow_out = sol_blow
    pte.flow_rate.aspirate = sol_asp
    pte.flow_rate.dispense = sol_disp

    pte.move_to(reservoir[well].top()) 
    pte.aspirate(51) # Aspirate air before aspirating solvent to help with a push out with the dispense. 
    
    pte.aspirate(sol_vol, reservoir[well].bottom(2)) # raised 3/10
    pte.move_to(reservoir[well].top())
    
    pte.flow_rate.aspirate = air_rate 
    pte.aspirate(air) 

    pte.dispense(sol_vol+10+air, reservoir[well].top(-2))
    pte.flow_rate.dispense = 1000
    pte.dispense(20)
    ctx.delay(1)
    pte.flow_rate.dispense = 1000
    pte.dispense(20)       
    
  
    # Solvent addition function
def solvent_addition(pte, sol_blow, sol_asp, sol_disp, sol_vol, reservoir, dest_plate, well, air_rate, air, location):
    
    pte.flow_rate.blow_out = sol_blow
    pte.flow_rate.aspirate = sol_asp
    pte.flow_rate.dispense = sol_disp
    

    pte.aspirate(31) # Aspirate air before aspirating solvent to help with a push out with the dispense. 
    
    pte.aspirate(sol_vol, reservoir[well].bottom(2)) # raised 3/10
    pte.move_to(reservoir[well].top(20), force_direct=True)
    pte.flow_rate.aspirate = air_rate 
    pte.aspirate(air) 

    # Move to destination plate and dispense 
    pte.move_to(dest_plate[location].top(5), force_direct=True)
    pte.dispense(sol_vol+10+air, dest_plate[location].top(-10)) 
    
    #Tip touch: side
    pte.move_to(dest_plate[location].top(-1).move(types.Point(x=1)))
    pte.flow_rate.dispense = 1000
    pte.dispense(20)   
    

    pte.move_to(dest_plate[location].top(5).move(types.Point(x=0)))
