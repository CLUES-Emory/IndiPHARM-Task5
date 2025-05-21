from opentrons import protocol_api
from opentrons import types
from opentrons.protocol_api import COLUMN, ROW, ALL

metadata = {
    'protocolName': '96-wp: Sample aliquot and ES addition for LC analysis',
    'author': 'Maria Cardelino + Catherine Mullins',
    'description': '96 wells only (A1): Adds 120 uL extraction solvent (ACN + internal standards) and 40 uL sample from 4 96-tube matrix racks to each well of a 396wp. Source plate is 96-tube matrix racks.'
}

requirements = {"robotType": "Flex", "apiLevel": "2.20"}

def run(protocol: protocol_api.ProtocolContext):

    #Turn lights on
    protocol.set_rail_lights(True)

    #Tell robot where the trashcan is
    trash = protocol.load_trash_bin("D3")
    
    ### Variable defintions ############################################################
    
    ## Variables for ES addition
    ES_vol = 120 # Acetonitrile volume for solvent transfer. 
    Well = 'A1' # Don't change this.
    ES_airgap = 20

    ES_blow_rate = 800 #ul/sec 
    ES_asp_rate = 40 #ul/sec 
    ES_disp_rate = 120 #ul/sec 
    ES_airgap_rate = 15 
    
    ## Variables for Sample Aliquot 
    asp_height = 3 # Distance in mm above the bottom of the matrix tubes that the pipette aspirates.    
    blow_height = 1 # Distance in mm ABOVE THE BOTTOM of the wp where sample dispense is performed.
    sample_vol = 40 # Volume of sample (uL)
    
    sample_blow_rate = 200 #ul/sec 
    sample_asp_rate = 10 #ul/sec 
    sample_disp_rate = 20 #ul/sec 
    
    #### Equipment Locations #########################################
        
    ## Destination plate on temp module at C1
    temp_mod_c = protocol.load_module('temperature module gen2', "C1")
    temp_mod_c.set_temperature(4)
    wellplate_dest = temp_mod_c.load_labware('abgene_96_wellplate_800ul') 
    
    ## ACN reservoir to avoid evaporation on temp module at B1
    temp_mod_b = protocol.load_module('temperature module gen2', "B1")
    temp_mod_b.set_temperature(4)     
    reservoir = temp_mod_b.load_labware('nest_1_reservoir_195ml')   
    
    ## Source plate
    temp_mod_d = protocol.load_module('temperature module gen2', "D1")
    temp_mod_d.set_temperature(4)
    wellplate_source = temp_mod_d.load_labware('matrix96well_96_tuberack_1000ul') 

    pipette = protocol.load_instrument(
        instrument_name="flex_96channel_1000"
    )
    
    #### Load labware: Pipette Configuration for sample aliquoting #################################
    
    ## TIPS    
    tiprack_sample = protocol.load_labware(
        "opentrons_flex_96_tiprack_50ul", "C3", #50 uL tips at D3
        adapter="opentrons_flex_96_tiprack_adapter") 
        
    ## CONFIGURATION 
    pipette.configure_nozzle_layout(
        style=ALL,
        start="A1",
        tip_racks=[tiprack_sample] # 50 uL tips at D3 for easy switchout.
    )
       
    #### Procedure for aliquoting samples ######################################################################################
    sample_aliquot(sample_blow_rate, sample_asp_rate, sample_disp_rate, tiprack_sample, pipette, sample_vol, wellplate_source, protocol, "A1", asp_height, wellplate_dest, blow_height)


    #### Load labware: Pipette Configuration for ES Addition ##################################
    
    ## TIPS 
    # 200 uL tips at B2
    tiprack1 = protocol.load_labware(
        "opentrons_flex_96_tiprack_200ul", "B3", #200 ul tips for ES at B1
        adapter="opentrons_flex_96_tiprack_adapter") 
        

    # #CONFIGURATION 
    pipette.configure_nozzle_layout( # 200 uL tips for ES at B1
        style=ALL,
        start="A1",
        tip_racks=[tiprack1]
    )
  
    #### Extraction Solvent Procedure ##################################

    # #Add extraction solvent (same tips throughout)
    pipette.pick_up_tip(tiprack1)
    prewet(pipette, ES_blow_rate, ES_asp_rate, ES_disp_rate, tiprack1, ES_vol, reservoir, Well, ES_airgap_rate, ES_airgap)
    prewet(pipette, ES_blow_rate, ES_asp_rate, ES_disp_rate, tiprack1, ES_vol, reservoir, Well, ES_airgap_rate, ES_airgap)
    prewet(pipette, ES_blow_rate, ES_asp_rate, ES_disp_rate, tiprack1, ES_vol, reservoir, Well, ES_airgap_rate, ES_airgap)

    ES_addition(pipette, ES_blow_rate, ES_asp_rate, ES_disp_rate, ES_vol, reservoir, wellplate_dest, Well, ES_airgap_rate, ES_airgap, "A1")
    
    pipette.drop_tip()     
    #pipette.drop_tip(tiprack1['A1']) #ONLY FOR TESTING; Re-use tips.
     
    ### END ES ADDITION #######################################################################
    

   
    #### END PROTOCOL SEQUENCE ###################################################################
    
    ### DEFINITIONS ############################################################################## 

    ## Prewetting function to prewet tips before dispensing any extraction solvent. 
def prewet(pte, ES_blow, ES_asp, ES_disp, ES_tip, ES_vol, reservoir, well, air_rate, air):
    
    pte.flow_rate.blow_out = ES_blow
    pte.flow_rate.aspirate = ES_asp
    pte.flow_rate.dispense = ES_disp   

    pte.move_to(reservoir[well].top()) 
    pte.aspirate(31)
    pte.aspirate(ES_vol, reservoir[well].bottom(1)) # v-shape; if reservoir definition is changed, change this! It will crash!
    pte.move_to((reservoir[well].top()))
    
    # change aspiration rate to airgap rate (15)
    pte.flow_rate.aspirate = air_rate
    pte.air_gap(air) 

    pte.dispense(ES_vol+30+air, reservoir[well].top(-2))


    ## Extraction solvent addition function
def ES_addition(pte, ES_asp, ES_disp, ES_blow, ES_vol, reservoir, dest_plate, well, air_rate, air, location):
    
    pte.flow_rate.blow_out = ES_blow
    pte.flow_rate.aspirate = ES_asp
    pte.flow_rate.dispense = ES_disp
    
    pte.move_to(reservoir[well].top()) 
    pte.aspirate(30) # Aspirate air before aspirating solvent to help with a push out with the dispense. 
    pte.aspirate(ES_vol, reservoir[well].bottom(1)) 
    pte.move_to((reservoir[well].top(5)))
    
    # change aspiration rate to airgap rate (15)
    pte.flow_rate.aspirate = air_rate 
    pte.air_gap(air) # Air gap to help retain the solvent.

    pte.move_to(dest_plate[location].top(5), force_direct=True)
    pte.dispense(ES_vol+30+air, dest_plate[location].bottom(5)) 

    #Tip touch: side
    pte.move_to(dest_plate[location].top(-1).move(types.Point(x=3))) 
    pte.move_to(dest_plate[location].top(-1).move(types.Point(x=-3)))  
    pte.move_to(dest_plate[location].top(-1).move(types.Point(x=3)))
    pte.move_to(dest_plate[location].top(-1).move(types.Point(x=0)))     
    
    ## Sample (plasma) aliquotting function
def sample_aliquot(samp_blow, samp_asp, samp_disp, tip, pte, vol, source, ctx, i, asp_dist, dest, blow):
    
    pte.flow_rate.blow_out = samp_blow 
    pte.flow_rate.aspirate = samp_asp  
    pte.flow_rate.dispense = samp_disp 

    pte.pick_up_tip(tip)
    pte.aspirate(vol, source["A1"].bottom(asp_dist))  # FIXED LOCATION for aspirating from samples. 
    ctx.delay(4) # Allow plasma to equilibrate in tip.
    pte.move_to(source["A1"].top(5), force_direct=True)
    
    pte.move_to(dest[i].top(5), force_direct=True)
    pte.dispense(vol, dest[i].bottom(blow))   # Dispense 16 mm above the bottom of the wells.
    
    
    pte.move_to(dest[i].top(-3).move(types.Point(x=-3)), speed = 10)       
    ctx.delay(2)
    pte.blow_out()
    pte.blow_out()       
    pte.drop_tip() #for actual run
    #pte.drop_tip(tip['A1']) #ONLY FOR TESTING; reuse tips.
    
    pte.reset_tipracks()   

