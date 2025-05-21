from opentrons import protocol_api
from opentrons import types
from opentrons.protocol_api import COLUMN, ROW, ALL

metadata = {
    'protocolName': '96-wp: Solvent dilution and supernatant transfer for LC analysis',
    'author': 'Maria Cardelino + Catherine Mullins',
    'description': '96 wells only (A1): Adds 60 uL solvent (water for C18, 1:1 ACN/water for HILIC) to each well of respective 96-well plates. Then adds 30 uL supernatant to each well of both well plates (C18 and HILIC) for LC analysis.'
}

requirements = {"robotType": "Flex", "apiLevel": "2.20"}

def run(protocol: protocol_api.ProtocolContext):

    # Turn on rail lights
    protocol.set_rail_lights(True)

    #Tell robot where the trashcan is
    trash = protocol.load_trash_bin("D3")

    #### Variable defintions ####################################
    
    ## Variables for solvent dilution ### 
       
    solvent_vol = 60 # Solvent volume 
    airgap = 10 # Airgap for solvent
    Well = 'A1' # Do not change
    
    solvent_blow_rate = 1000 #ul/sec 
    solvent_asp_rate = 40 # ul/sec 
    solvent_disp_rate = 120 # ul/sec 
    solvent_airgap_rate = 30 # ul/sec    
    
    ## Variables for supernatant transfer
    asp_height = 4.5 # This is the distance in mm ABOVE THE BOTTOM of the 96 wp that the pipette aspirates.                             
        
        
    blow_height = 10 # Distance in mm ABOVE THE BOTTOM of the 96 wp where the supernatant dispense is performed.
    
    sample_vol = 30 # Volume of supernatant (uL) 
    
    airgap_sample = 10  # Airgap size (uL) for supernatant
    sup_air_rate = 10  # Airgap aspiration rate
    
    sup_asp_rate = 15 #ul/sec   # 2/13 changed from 10!
    sup_disp_rate = 92 #ul/sec 
    
    #### Equipment Locations ######################################
    
    ## Location for tips
    tiprack_200_hilic = protocol.load_labware(
        'opentrons_flex_96_tiprack_200ul', 'A3', 
        adapter='opentrons_flex_96_tiprack_adapter') 
    
    tiprack_200_c18 = protocol.load_labware(
        'opentrons_flex_96_tiprack_200ul', 'B3', 
        adapter='opentrons_flex_96_tiprack_adapter') 
    
    tiprack_200_sample = protocol.load_labware(
        'opentrons_flex_96_tiprack_200ul', 'C3',
        adapter='opentrons_flex_96_tiprack_adapter')    
       

    ## Location for reservoirs    
    # C18 - just water
    reservoir_water = protocol.load_labware('nest_1_reservoir_195ml', 'C2') 
    
    # HILIC - water/ACN
    reservoir_acn_water = protocol.load_labware('nest_1_reservoir_195ml', 'B2') 

    ## Location for temperature modules and destination plates    
    temp_module_1 = protocol.load_module('temperature module gen2', 'B1')
    temp_module_1.set_temperature(4)
    hilic_plate = temp_module_1.load_labware('abgene_96_wellplate_800ul')                    

    temp_module_2 = protocol.load_module('temperature module gen2', 'C1')
    temp_module_2.set_temperature(4)
    c18_plate = temp_module_2.load_labware('abgene_96_wellplate_800ul')                     

    ## Location for source plate (well plate) 
    temp_module_3 = protocol.load_module('temperature module gen2', 'D1')
    temp_module_3.set_temperature(4)
    source_plate = temp_module_3.load_labware('abgene_96_wellplate_800ul') 
   
    ##### Load labware: Pipette Configuration 1 ##################################
    pipette = protocol.load_instrument(
        instrument_name="flex_96channel_1000"
    )

    #  HILIC solvent first ; volatile
    pipette.configure_nozzle_layout(
        style=ALL,
        start="A1",
        tip_racks=[tiprack_200_hilic] 
    )

    #### Solvent Transfer to Destination Plates ##################################
    # First, transfer ACN/water to HILIC plate
    pipette.pick_up_tip(tiprack_200_hilic) 
    
    prewet(pipette, solvent_blow_rate, solvent_asp_rate, solvent_disp_rate, solvent_vol, reservoir_acn_water, Well, solvent_airgap_rate, airgap)
    prewet(pipette, solvent_blow_rate, solvent_asp_rate, solvent_disp_rate, solvent_vol, reservoir_acn_water, Well, solvent_airgap_rate, airgap)
    prewet(pipette, solvent_blow_rate, solvent_asp_rate, solvent_disp_rate, solvent_vol, reservoir_acn_water, Well, solvent_airgap_rate, airgap)

    solvent_addition(pipette, solvent_blow_rate, solvent_asp_rate, solvent_disp_rate, solvent_vol, reservoir_acn_water, hilic_plate, Well, solvent_airgap_rate, airgap, "A1", 1)
    
    pipette.drop_tip() #uncomment for actual run
    #pipette.drop_tip(tiprack_200_hilic['A1']) #reuse tips for testing
    
    #### Change to second 200 uL tiprack ##################################
    pipette.configure_nozzle_layout(
        style=ALL,
        start="A1",
        tip_racks=[tiprack_200_c18] 
    )
    
    # Second, transfer water to C18 plate       
    pipette.pick_up_tip(tiprack_200_c18)     

    solvent_addition(pipette, solvent_blow_rate, solvent_asp_rate, solvent_disp_rate, solvent_vol, reservoir_water, c18_plate, Well, solvent_airgap_rate, airgap, "A1", 5)
   
    pipette.drop_tip() #uncomment for actual run
    #pipette.drop_tip(tiprack_200_c18['A1']) #reuse tips for testing
   
    ### END SOLVENT ADDITION ###############################################
    
    # Pause for user to add source plate
    protocol.pause('End solvent addition. GENTLY move the sample plate from the centrifuge to position D1; GENTLY remove foil seal, then resume protocol.')
    

    #### Supernatant Transfer: from source plate to C18 and HILIC  well destination plates ##############################
       
    #### Pipette configuration ###########################
    
    pipette.configure_nozzle_layout(
        style=ALL,
        start="A1", 
        tip_racks=[tiprack_200_sample] 
    )
         
    
    #### FIRST (A1) SUPERNATANT TRANSFER - 96 AT A TIME  ######################################
    
    transfer_supernatant(pipette, source_plate, c18_plate, hilic_plate, tiprack_200_sample, sup_asp_rate, sup_disp_rate, sample_vol, airgap_sample, sup_air_rate, blow_height, asp_height, "A1")

    protocol.comment('Supernatant transfer complete. Protocol finished.')

    #### END PROTOCOL SEQUENCE #################################################################################################################################   
    
    #### DEFINITIONS ########################################################
    
    # Supernatant Transfer function - transfers supernant 96 wells at a time from source  well plate to destination  well plates (2) - C18 and HILIC.                                                                   
def transfer_supernatant(pte, source_plate, c18_plate, hilic_plate, tiprack, sup_asp, sup_disp, svol, air, air_rate, blow, x, well_id):

    pte.flow_rate.aspirate = sup_asp 
    pte.flow_rate.dispense = sup_disp   
    
    # Pick up a new tip from the 50 uL tip rack
    pte.pick_up_tip(tiprack)
        
    pte.move_to(source_plate[well_id].top())
    pte.aspirate(31)
    pte.move_to(source_plate[well_id].bottom(x), speed = 10)
    pte.aspirate(svol) 
    pte.move_to(source_plate[well_id].top(5))
    
    pte.flow_rate.aspirate = air_rate 
    pte.air_gap(air) 
    
    pte.move_to(c18_plate[well_id].top(5), force_direct=True)
    pte.dispense(svol + air, c18_plate[well_id].bottom(blow))  # Dispense the supernatant and air 15 mm from BOTTOM    
    pte.flow_rate.aspirate = 1000
    pte.dispense(30, c18_plate[well_id].bottom(blow)) 
    pte.move_to(c18_plate[well_id].top(-1).move(types.Point(x=3)))
    pte.move_to(c18_plate[well_id].top(-1).move(types.Point(x=-3)))
    pte.move_to(c18_plate[well_id].top(-1).move(types.Point(x=3)))    
    pte.move_to(c18_plate[well_id].top(0).move(types.Point(x=0)))     
    pte.move_to(c18_plate[well_id].top(5).move(types.Point(x=0)))
    
    pte.move_to(source_plate[well_id].top(5), force_direct=True)
    pte.aspirate(30)
    pte.move_to(source_plate[well_id].bottom(x), speed = 10)
    pte.flow_rate.aspirate = sup_asp 
    pte.aspirate(svol) 
    pte.move_to(source_plate[well_id].top())
    
    pte.flow_rate.aspirate = air_rate 
    pte.air_gap(air) 
    
    pte.move_to(hilic_plate[well_id].top(5), force_direct=True)    
    pte.dispense(svol + air, hilic_plate[well_id].bottom(blow))  # Dispense the supernatant and air 15 mm from BOTTOM    
    pte.flow_rate.aspirate = 1000
    pte.dispense(30, hilic_plate[well_id].bottom(blow))    
    pte.move_to(hilic_plate[well_id].top(-1).move(types.Point(x=3)))
    pte.move_to(hilic_plate[well_id].top(-1).move(types.Point(x=-3)))
    pte.move_to(hilic_plate[well_id].top(-1).move(types.Point(x=3)))    
    pte.move_to(hilic_plate[well_id].top(0).move(types.Point(x=0)))
    pte.move_to(hilic_plate[well_id].top(5).move(types.Point(x=0)))
  
    
    ## FINISH 
    
    pte.drop_tip() # Uncomment for actual run
    #pte.drop_tip(tiprack['A1']) #ONLY FOR TESTING; reuse tips.
    
    pte.reset_tipracks() 
   
    # ES prewetting function  
def prewet(pte, sol_blow, sol_asp, sol_disp, sol_vol, reservoir, well, air_rate, air):
    
    pte.flow_rate.blow_out = sol_blow
    pte.flow_rate.aspirate = sol_asp
    pte.flow_rate.dispense = sol_disp

    pte.move_to(reservoir[well].top()) 
    pte.aspirate(30) # Aspirate air before aspirating solvent to help with a push out with the dispense. 
    
    pte.aspirate(sol_vol, reservoir[well].bottom(2)) # raised 3/10
    pte.move_to(reservoir[well].top())
    
    pte.flow_rate.aspirate = air_rate 
    pte.air_gap(air) 

    pte.dispense(sol_vol+30+air, reservoir[well].top(-2))
    
    pte.blow_out()
    pte.blow_out()
  
    # Solvent addition function
def solvent_addition(pte, sol_blow, sol_asp, sol_disp, sol_vol, reservoir, dest_plate, well, air_rate, air, location, solv_disp):
    
    pte.flow_rate.blow_out = sol_blow
    pte.flow_rate.aspirate = sol_asp
    pte.flow_rate.dispense = sol_disp
    
    pte.move_to(reservoir[well].top()) 
    pte.aspirate(30) # Aspirate air before aspirating solvent to help with a push out with the dispense. 
    
    pte.aspirate(sol_vol, reservoir[well].bottom(2)) 
    pte.move_to((reservoir[well].top()))
    pte.flow_rate.aspirate = air_rate 
    pte.air_gap(air) # Air gap to help retain solvent.
    
    # Move to destination plate and dispense 
    pte.dispense(sol_vol+30+air, dest_plate[location].bottom(solv_disp))
    pte.blow_out()
    pte.blow_out() 
    
    #Tip touch: side
    pte.move_to(dest_plate[location].top(-1).move(types.Point(x=-3)), speed = 10)
    pte.move_to(dest_plate[location].top(-1).move(types.Point(x=3)), speed = 10)  
    pte.move_to(dest_plate[location].top(-1).move(types.Point(x=-3)), speed = 10)