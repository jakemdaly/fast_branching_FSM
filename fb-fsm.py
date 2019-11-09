"""
 Keysight Confidential
 Copyright Keysight Technologies 2019

 @author ADGS Quantum Apps Dev

The goal of this application example is to show how to use HVI Port blocks placed in the sandbox of an M3xxxA module FPGA
to allow communication between an HVI sequence designed using HVI API and custom blocks loaded into an instrument FPGA sandbox
using Pathwave FPGA.

Please note that there are two types of HVI Port blocks that can be placed within the FPGA sandbox of an instrument: memory maps and register banks.
Read/write of both type of HVI Port blocks is tested in this application example.

The complete list of HVI API functionality showcased in this application example is as follows:
 * Read/write data from/to an HVI sequence to/from an HVI port (Memory Map) inserted in a custom FPGA FW
 * Read/write data from/to an HVI sequence to/from an HVI port (Register bank) inserted in a custom FPGA FW
 * Read/write PXI line values from a custom FPGA FW
 * Usage of HVI Actions and Events to communicate with a custom FPGA FW

The flow-chart of the HVI sequence included in this code example is explained in the application note document titled "HVI Integration with Pathwave FPGA".
"""
import sys

sys.path.append('C:\Program Files (x86)\Keysight\SD1\Libraries\Python')
# sys.path.append('C:\Program Files\Keysight\HVI\api\python\keysight_pathwave_hvi')
import keysightSD1
import keysight_pathwave_hvi as pyhvi
import datetime
from k7z import K7Z
import os

def main():
    # User can choose to run the code in simulation mode or on real HW:
    hwSimulated = False
    if hwSimulated == True:
        print("Program is running in Simulation Mode")

    # Clear chassis reservations
    os.system(r"Rc-Tool.exe clear HVI_ALL")

    ####################
    # Open PXI modules
    ###################
    # NOTE Please go inside openModules() and insert chassis and slot numbers of the modules you want to open
    openModulesResult = openModules(hwSimulated)
    moduleList = openModulesResult[0]
    minChassis = openModulesResult[1]  # variable to be used for simulated mode
    maxChassis = openModulesResult[2]  # variable to be used for simulated mode
    masterModule = moduleList[0]
    slaveModule = moduleList[1]
    awgTriggerList = [0b1111]
    nChannels = [4]

    # Load custom FPGA FW designed using Pathwave FPGA
    masterDigFile = "mySandbox.k7z"
    error = masterModule.FPGAload(masterDigFile)
    if error < 0:
        print("masterModule.FPGAload() error! Error code: {} Error message: {}".format(error,
                                                                                       keysightSD1.SD_Error.getErrorMessage(
                                                                                           error)))

    # Get master module's FPGA registers info
    print("Registers contained in Master Module:")
    numRegisters = 6
    registers = masterModule.FPGAgetSandBoxRegisters(numRegisters)
    # Print the register properties in register list
    for register in registers:
        print("Register name: {}".format(register.Name))
        print("Register size [bytes]: {}".format(register.Length))
        print("Register address offset [bytes]: {}".format(register.Address))
        print("Register access: {}".format(register.AccessType))
    print()

    # # Get HVI registers for debugging purposes
    # sandbox = K7Z("mySandbox.k7z")
    # for reg_name in sandbox:
    #     print(reg_name)



    ######################################
    # Configure resources in HVI instance
    ######################################
    # Create HVI instance
    hviResourceName = "KtHvi"
    hvi = pyhvi.KtHvi(hviResourceName)

    # Create a list of HVI engines
    engineIdList = []
    for module in moduleList:
        engineIdList.append(module.hvi.engines.main_engine)

    # Add engines to the HVI instance for HVI to use them
    masterEngine = hvi.engines.add(engineIdList[0], "MasterEngine")
    slaveEngine = hvi.engines.add(engineIdList[1], "SlaveEngine")

    # Get engine sandbox
    sandboxName = "sandbox0"
    masterSandbox = masterEngine.fpga_sandboxes[sandboxName]

    # Load to the sandboxes .k7z project created using Pathwave FPGA
    # This operation is necessary for HVI to list all the FPGA blocks contrined in the designed FPGA FW
    masterSandbox.load_from_k7z(masterDigFile)

    # Add chassis
    if hwSimulated:
        for chassis in range(minChassis, maxChassis + 1):
            hvi.platform.chassis.add_with_options(chassis, "Simulate=True,DriverSetup=model=M9018B,NoDriver=True")
    else:
        # Adds physical chassis connected in the system to the HVI instrument
        hvi.platform.chassis.add_auto_detect()

    """ Multi-chassis setup
    # In case of multiple chassis, chassis PXI lines need to be shared using squid boards. Squid board positions need to be defined in the program.
    # To add squidboards use: interconnects.AddSquidboards(chassis1, chassis1SquidSlot, chassis2, chassis2SquidSlot);
    # First and last chassis have only one squid board in the middle segment. Middle chassis have two squid boards
    # in middle and lateral segments respectively. Adjachent chassis have their squid boards connected in diagonal.
    # See application note for more details.
    #
    #interconnects = hvi.platform.interconnects
    #interconnects.add_squidboards(1, 9, 2, 9)
    #interconnects.add_squidboards(2, 16, 3, 9)
    #interconnects.add_squidboards(3, 18, 4, 10)
    """

    ######################################
    # HVI Sequence Resource Definitions
    ######################################
    # Create sequences
    masterSeq = masterEngine.main_sequence
    slaveSeq = slaveEngine.main_sequence

    # Create registers in master module to count the occurrences of FPGA_UserAction_4, read PXI values, quit sequence
    cycleCount = masterSeq.registers.add("cycleCount", pyhvi.RegisterSize.SHORT)
    hviRegFSMValues = masterSeq.registers.add("HviRegFSMValues", pyhvi.RegisterSize.SHORT)
    regCounter = masterSeq.registers.add("RegCounter", pyhvi.RegisterSize.SHORT)
    hviQuit = masterSeq.registers.add("HviMemoryMap", pyhvi.RegisterSize.SHORT)
    memMapValue = 1000
    regCounter.set_initial_value(memMapValue)
    # Create register in slave module to read PXI lines values
    destinationRegs = []
    for ii in range(1,hvi.engines.count):
        engine = hvi.engines[ii]
        seq = engine.main_sequence
        slaveHviRegWavenumStore = slaveSeq.registers.add("HviRegWavenumStore", pyhvi.RegisterSize.SHORT)
        destinationRegs.append(slaveHviRegWavenumStore)
    bitsToShare = 16
    startDelay = 0
    nCycles = 1
    prescaler = 0
    nAWG = 0

    # Events: add FpgaUserEvent4 to the list of events of the master engine
    fpgaUserEvent4 = masterModule.hvi.events.fpga_user_4
    hvi.engines[0].events.add(fpgaUserEvent4, "FpgaUserEvent4")

    # Actions: add FpgaUserAction4 to the list of actions of the master engine
    fpgaUserAction4 = masterModule.hvi.actions.fpga_user_4
    hvi.engines[0].actions.add(fpgaUserAction4, "FpgaUserAction4")
    fpgaUserAction7 = masterModule.hvi.actions.fpga_user_7
    hvi.engines[0].actions.add(fpgaUserAction7, "FpgaUserAction7")

    # Assign PXI lines to HVI object to be used for HVI-managed synch, data sharing, etc.
    # NOTE1: in this application example lines PXI4-PXI7 are used by the sandbox to exchange info between master and slave modules
    # NOTE2: users are required to make an estimation of how many PXI lines are required to be listed as HVI trigger resources and be reserved for an HVI execution.
    # Typically 2-3 PXI lines are enough when running applications in a single chassis. Multiple-chassis setups require additional trigger lines
    triggerResources = [pyhvi.TriggerResourceId.PXI_TRIGGER0, pyhvi.TriggerResourceId.PXI_TRIGGER1, pyhvi.TriggerResourceId.PXI_TRIGGER3] #, pyhvi.TriggerResourceId.PXI_TRIGGER4, pyhvi.TriggerResourceId.PXI_TRIGGER5, pyhvi.TriggerResourceId.PXI_TRIGGER6, pyhvi.TriggerResourceId.PXI_TRIGGER7]
    hvi.platform.sync_resources = triggerResources

    # Assign clock frequences that are outside the set of the clock frequencies of each hvi engine
    nonHVIclocks = [10e6]
    hvi.synchronization.non_hvi_core_clocks = nonHVIclocks

    ######################################
    # Start HVI sequence creation
    ######################################
    print("Press enter to begin creation of the HVI sequence")
    input()

    #   WAIT FOR DATA READY  #
    # Add wait for an event on HviEvent4 block
    waitEvent4 = masterSeq.programming.add_wait_event("Wait for FpgaUserEvent4", 10)
    waitEvent4.event = hvi.engines[0].events["FpgaUserEvent4"]
    waitEvent4.set_mode(pyhvi.EventDetectionMode.TRANSITION_TO_ACTIVE, pyhvi.SyncMode.IMMEDIATE)

    #   READ DATA VALUE FROM REG   #
    # Add read HVI register block. Because UserEvent4 has occured, we know that the data is ready in the register
    readWavenumDig = masterSeq.programming.add_fpga_register_read("Read Waveform Number", 20)
    readWavenumDig.destination = hviRegFSMValues
    readWavenumDig.fpga_register = masterEngine.fpga_sandboxes[0].hvi_registers["Register_Bank_HviAnalogChannelsIn"]

    #   SYNC JUNCTION W/ REG SHARE   #
    # Synchronize the AWGs to the Digitizer, and perform a register share
    junctionName = "GlobalJunction"
    junctionTime_ns = 10
    junction1 = hvi.programming.add_junction(junctionName, junctionTime_ns)
    # Configure Register Share
    regShare = junction1.register_sharing.add("regSharing", hviRegFSMValues, bitsToShare, destinationRegs)

    #   RESET FSM WITH USER ACTION 7    #
    # Asserting high on user action 7 will reset the FSM so it's ready for the next sequence
    instAction4 = masterSeq.programming.add_instruction("Execute Action 4", 10, hvi.instructions.action_execute.id)
    instAction4.set_parameter(hvi.instructions.action_execute.action, fpgaUserAction7)


    #   QUEUE WAVEFORMS IN AWGS    #
    # Add a queue waveform block in each AWG. Each AWG will read the waveform value from its register
    for index in range(1, hvi.engines.count):
        # Obtain master sequence from each module engine to add instructions to
        engine = hvi.engines[index]
        seq = engine.main_sequence

        # Add AWG Queue Waveform to each sequence
        for NAWG in range(1,nChannels[index-1]+1): #index-1 because index=0 is Dig, and nChannels[] is AWGs
            instrLabel = "awgQueueWaveform" + str(NAWG)
            instruction0 = seq.programming.add_instruction(instrLabel, 10, moduleList[index].hvi.instructions.queue_waveform.id)
            # Set each parameter of this instruction
            instruction0.set_parameter(moduleList[index].hvi.instructions.queue_waveform.waveform_number.id, seq.registers["HviRegWavenumStore"])
            instruction0.set_parameter(moduleList[index].hvi.instructions.queue_waveform.channel.id, NAWG)
            instruction0.set_parameter(moduleList[index].hvi.instructions.queue_waveform.trigger_mode.id, keysightSD1.SD_TriggerModes.SWHVITRIG)
            instruction0.set_parameter(moduleList[index].hvi.instructions.queue_waveform.start_delay.id, startDelay)
            instruction0.set_parameter(moduleList[index].hvi.instructions.queue_waveform.cycles.id, nCycles)
            instruction0.set_parameter(moduleList[index].hvi.instructions.queue_waveform.prescaler.id, prescaler)

    #   SYNC JUNCTION   #
    # Re-sync HVI sequences after queuewaveform
    hvi.programming.add_junction("QueueWfmDone", 1000)


    #   AWG TRIGGER ALL   #
    # Send software trigger to trigger all the AWGs
    for index in range(1, hvi.engines.count):
        engine = hvi.engines[index]
        seq = engine.main_sequence

        instruction2 = seq.programming.add_instruction("AWG trigger", 2e3, hvi.instructions.action_execute.id)
        instruction2.set_parameter(hvi.instructions.action_execute.action, awgTriggerList[index-1])

    #   INCR CYCLE COUNT    #
    cycleInc = masterSeq.programming.add_instruction("cycleCount++", 10, hvi.instructions.add.id)
    cycleInc.set_parameter(hvi.instructions.add.left_operand, 1)
    cycleInc.set_parameter(hvi.instructions.add.right_operand, cycleCount)
    cycleInc.set_parameter(hvi.instructions.add.result_register, cycleCount)


    #   GLOBAL JUMP     #
    jumpName = "jumpStatement"
    jumpTime = 10000
    jumpDestination = "Start"
    hvi.programming.add_jump(jumpName, jumpTime, jumpDestination)

    hvi.programming.add_end("EndOfSequence", 10)

    ############################################################################
    ### END OF SEQUENCE
    ############################################################################

    ######################################
    ## Compile, load, run HVI sequence
    ######################################

    # Compile the sequence
    hvi.compile()

    # Load the HVI to HW: load sequences, config triggers/events/..., lock resources, etc.
    hvi.load_to_hw()

    # Start HVI sequence execution in each PXI module
    print("Press enter to start HVI...")
    input()
    time = datetime.timedelta(seconds=0)
    hvi.run(time)

    # User controlled loop
    counter = 0
    regReadPxi = 0
    value = 0
    while True:
        print("N. of iterations = {}".format(cycleCount.read()))
        print("Press enter to trigger a User Event and execute a User Action, press q to exit")
        key = input()

        if key == 'q':
            hviQuit.write(1)
            break
        else:
            # in master module write host register connected to PXI outputs
            counter += 1
            memMapValue += 1
            regCounter.write(memMapValue)
            triggerFpgaUserEvent(masterSandbox)
            # time.sleep(.01)

    # Release HVI instance from HW (unlock resources)
    print("Exiting...")

    hvi.release_hw()

    # Close modules
    for module in moduleList:
        module.close()


class ModuleDescriptor:
    chassisNumber = 0
    slotNumber = 0
    options = ""
    instrType = "awg"

    def __init__(self, chassisNumber, slotNumber, options, instrType="awg"):
        self.chassisNumber = chassisNumber
        self.slotNumber = slotNumber
        self.options = options
        self.instrType = instrType


def openModules(hwSimulated):
    # Simulation or real HW
    if hwSimulated:
        options = ",simulate=true"
    elif hwSimulated == False:
        options = ""
    else:
        print("hwSimulated not set to valid value")
        sys.exit()

    # Channel numbering option
    channelOption = "channelNumbering=keysight";
    options = channelOption + options

    # Update chassis and slot numbers to your modules' values
    moduleDescriptors = [ModuleDescriptor(chassisNumber=1, slotNumber=8, options=options, instrType="dig"),
                         ModuleDescriptor(chassisNumber=1, slotNumber=11, options=options)]
    moduleList = []
    minChassis = 1
    maxChassis = 1

    # Open modules
    for descriptor in moduleDescriptors:
        newModule = keysightSD1.SD_AIN() if descriptor.instrType=="dig" else keysightSD1.SD_AOU()
        # newModule = keysightSD1.SD_AOU()  # change to SD_AIN() if you want to use digitizers

        chassisNumber = descriptor.chassisNumber
        productName = ""  # change to "" for a generic instrument
        id = newModule.openWithOptions(productName, chassisNumber, descriptor.slotNumber, options)
        if id < 0:
            print("Error opening module in chassis {}, slot {}! Error code: {}, {}".format(descriptor.chassisNumber,
                                                                                           descriptor.slotNumber, id,
                                                                                           keysightSD1.SD_Error.getErrorMessage(
                                                                                               id)))
            print("Press any key to exit...")
            input()
            sys.exit()

        moduleList.append(newModule)
        if minChassis == 0 or minChassis > chassisNumber:
            minChassis = chassisNumber

        if maxChassis == 0 or maxChassis < chassisNumber:
            maxChassis = chassisNumber

    return (moduleList, minChassis, maxChassis)


def triggerFpgaUserEvent(sandbox):
    # Write a 1-0 to register "Register_Bank_HviEvent4" within an HVI Port Register Bank
    # Please update the registerName to the actual name of your register if necessary
    registerName = "Register_Bank_HviEvent4"
    regEvent4 = sandbox.hvi_registers[registerName]
    regEvent4.write(1)
    regEvent4.write(0)


if __name__ == '__main__':
    main()