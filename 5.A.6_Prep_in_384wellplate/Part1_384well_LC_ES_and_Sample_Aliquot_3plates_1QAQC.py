from opentrons import protocol_api
from opentrons import types
from opentrons.protocol_api import COLUMN, ROW, ALL

metadata = {
    'protocolName': 'Protocol#1: ES addition and aliquot for LC analysis - From Matrix Racks',
    'author': 'Maria Cardelino + Catherine Mullins',
    'description': 'Adds 90 uL extraction solvent (ACN + internal standards) and 30 uL sample from 3 96-tube matrix racks (2 sample, 1 QAQC) to a 384-well plate.'
}

requirements = {"robotType": "Flex", "apiLevel": "2.20"}

def run(protocol: protocol_api.ProtocolContext):

    #Turn lights on
    protocol.set_rail_lights(True)

    #Tell robot where the trashcan is
    trash = protocol.load_trash_bin("D3")
    
    ### Variable defintions ############################################################
    #CEM note 3/10/25: some of these variables may have been written into the definitions; if trying to change something, check there.
    
    ## Variables for ES addition
    ES_vol = 90 # Acetonitrile volume for solvent transfer. 
    Well = 'A1' # Don't change this.
    ES_airgap = 10
    last_col_sample = 10
    last_col_QAQC = 6

    ES_blow_rate = 800 #ul/sec 
    ES_asp_rate = 92 #ul/sec 
    ES_disp_rate = 40 #ul/sec 
    ES_airgap_rate = 15 
    
    ## Variables for Sample Aliquot 
    blow_height = 12 # Distance in mm ABOVE THE BOTTOM of the wp where sample dispense is performed.
    sample_vol = 30 # Volume of sample (uL)
    
    sample_blow_rate = 200 #ul/sec 
    sample_asp_rate = 10 #ul/sec 
    sample_disp_rate = 20 #ul/sec 
    
    #### Equipment Locations #########################################
        
    ## Destination plate on temp module at C1
    temp_mod_c = protocol.load_module('temperature module gen2', "C1")
    temp_mod_c.set_temperature(4)
    wellplate_dest = temp_mod_c.load_labware('thermofisher_384_wellplate_250ul') 
    
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
    tiprack_sample_1 = protocol.load_labware(
        "opentrons_flex_96_tiprack_50ul", "A1", 
        adapter="opentrons_flex_96_tiprack_adapter") 
        
    tiprack_sample_2 = protocol.load_labware(
        "opentrons_flex_96_tiprack_50ul", "A2", 
        adapter="opentrons_flex_96_tiprack_adapter")        

    tiprack_sample_3 = protocol.load_labware(
        "opentrons_flex_96_tiprack_50ul", "A3", 
        adapter="opentrons_flex_96_tiprack_adapter")   
        
    tiprack_qaqc = protocol.load_labware(
        "opentrons_flex_96_tiprack_50ul", "A", 
        adapter="opentrons_flex_96_tiprack_adapter")

    # 200 uL tips at 
    tiprack1 = protocol.load_labware(
        "opentrons_flex_96_tiprack_200ul", "B3", 
        adapter="opentrons_flex_96_tiprack_adapter") 
   
    
    #### Load labware: Pipette Configuration for ES Addition ##################################
  
    # #CONFIGURATION 
    #Only need pipettes in columns 1 and 2!!!!
    pipette.configure_nozzle_layout( 
        style=ALL,
        start="A1",
        tip_racks=[tiprack1]
    )
  
    #### Extraction Solvent Procedure ##################################

    # #Add extraction solvent (same tips throughout)
    pipette.pick_up_tip(tiprack1)
    prewet(pipette, ES_blow_rate, ES_asp_rate, ES_disp_rate, tiprack1, ES_vol, reservoir, "A1", ES_airgap_rate, ES_airgap)
    prewet(pipette, ES_blow_rate, ES_asp_rate, ES_disp_rate, tiprack1, ES_vol, reservoir, "A1", ES_airgap_rate, ES_airgap)
    prewet(pipette, ES_blow_rate, ES_asp_rate, ES_disp_rate, tiprack1, ES_vol, reservoir, "A1", ES_airgap_rate, ES_airgap)

#ES Aspiration Depth    
    ID = [f"A{i}" for i in range(1, 19, 4) for i in (i, i+1)] + [f"B{i}" for i in range(1, 10, 4)]
    start = 10
    step = 1.1
    depth = [start + i * step for i in range(len(ID))]
    
    for i, (well, depth_val) in enumerate(zip(ID, depth)):
        ES_addition(pipette, ES_blow_rate, ES_asp_rate, ES_disp_rate, ES_vol, reservoir, wellplate_dest, "A1", ES_airgap_rate, ES_airgap, i, ID, i, depth)
  
    pipette.drop_tip()     
    #pipette.drop_tip(tiprack1['A1']) #ONLY FOR TESTING; Re-use tips.

    protocol.pause('Place uncapped samples in D1, then continue')

    ### END ES ADDITION #######################################################################

    ## CONFIGURATION 
    pipette.configure_nozzle_layout(
        style=ALL,
        start="A1",
        tip_racks=[tiprack_sample_1, tiprack_sample_2, tiprack_sample_3] # 50 uL tips at D3 for easy switchout.
    )
       
    #### Procedure for aliquoting samples ######################################################################################
    #only 10 columns tips needed
    sample_aliquot(sample_blow_rate, sample_asp_rate, sample_disp_rate, tiprack_sample_1, pipette, sample_vol, wellplate_source, protocol, "A1", 6, wellplate_dest, blow_height)
    pipette.move_to(tiprack1["A1"].top(50))
    protocol.pause('Replace sample plate, then resume.') 
    
    #only 10 columns tips needed
    sample_aliquot(sample_blow_rate, sample_asp_rate, sample_disp_rate, tiprack_sample_2, pipette, sample_vol, wellplate_source, protocol, "A2", 6, wellplate_dest, blow_height)
    pipette.move_to(tiprack1["A1"].top(50))
    protocol.pause('Replace sample plate, then resume.')

    #only 6 columns tips needed
    sample_aliquot(sample_blow_rate, sample_asp_rate, sample_disp_rate, tiprack_sample_3, pipette, sample_vol, wellplate_source, protocol, "B1", 3, wellplate_dest, blow_height)
    pipette.move_to(tiprack1["A1"].top(50))

    #### END PROTOCOL SEQUENCE ###################################################################
    
    ### DEFINITIONS ############################################################################## 

    ## Prewetting function to prewet tips before dispensing any extraction solvent. 
def prewet(pte, ES_blow, ES_asp, ES_disp, ES_tip, ES_vol, reservoir, well, air_rate, air):
    
    pte.flow_rate.blow_out = ES_blow
    pte.flow_rate.aspirate = ES_asp
    pte.flow_rate.dispense = ES_disp   

    pte.move_to(reservoir[well].top()) 
    pte.aspirate(31)
    pte.aspirate(ES_vol, reservoir[well].top(-10)) # v-shape; if reservoir definition is changed, change this! It will crash!
    pte.move_to((reservoir[well].top()))
    
    # change aspiration rate to airgap rate (15)
    pte.flow_rate.aspirate = air_rate
    pte.aspirate(air) 
    pte.dispense(ES_vol+10+air, reservoir[well].top(-2))
    pte.move_to(reservoir[well].top(-0.5).move(types.Point(x=4)))
    pte.flow_rate.dispense = 1000
    pte.dispense(20) 
    
    ## Extraction solvent addition function
def ES_addition(pte, ES_blow, ES_asp, ES_disp, ES_vol, reservoir, dest_plate, well, air_rate, air, i, ID, j, depth):
    
    pte.flow_rate.blow_out = ES_blow
    pte.flow_rate.aspirate = ES_asp
    pte.flow_rate.dispense = ES_disp
    
    pte.move_to(reservoir[well].top(5), force_direct=True) 
    pte.aspirate(31) # Aspirate air before aspirating solvent to help with a push out with the dispense. 
    pte.move_to((reservoir[well].top(5)))
    pte.aspirate(ES_vol, reservoir[well].top(-depth[j])) 
    pte.move_to((reservoir[well].top(5)))
    
    # change aspiration rate to airgap rate (15)
    pte.flow_rate.aspirate = air_rate 
    pte.aspirate(air) # Air gap to help retain the solvent.

    pte.move_to(dest_plate[ID[i]].top(15), force_direct=True)
    pte.dispense(ES_vol+10+air, dest_plate[ID[i]].top(-2)) 

    #Tip touch + blow out: side
    pte.move_to(dest_plate[ID[i]].top(-0.5).move(types.Point(x=1)))
    pte.move_to(dest_plate[ID[i]].top(-0.5).move(types.Point(x=-1)))     
    pte.flow_rate.dispense = 1000
    pte.dispense(20) 
    pte.move_to(dest_plate[ID[i]].top(10).move(types.Point(x=0)))     
    
    ## Sample (plasma) aliquotting function
def sample_aliquot(samp_blow, samp_asp, samp_disp, tip, pte, vol, source, ctx, i, asp_dist, dest, blow):
    
    pte.flow_rate.blow_out = samp_blow 
    pte.flow_rate.aspirate = samp_asp  
    pte.flow_rate.dispense = samp_disp 

    pte.pick_up_tip(tip)
    pte.flow_rate.aspirate = 1000    
    pte.aspirate(20, source["A1"].top()) #air aspiration
    pte.flow_rate.aspirate = samp_asp 
    pte.aspirate(vol, source["A1"].bottom(asp_dist))  
    ctx.delay(4) # Allow plasma to equilibrate in tip.
    pte.move_to(source["A1"].top(5), force_direct=True)
    
    pte.move_to(dest[i].top(25), force_direct=True)
    pte.dispense(vol, dest[i].bottom(blow))
    
    pte.move_to(dest[i].top(-(10.5)))
    pte.move_to(dest[i].bottom(blow))        
    ctx.delay(2)   
    pte.flow_rate.dispense = 1000
    pte.dispense(19)    
        
    pte.drop_tip() #for actual run
    #pte.drop_tip(tip['A1']) #ONLY FOR TESTING; reuse tips.
    
    pte.reset_tipracks()   

