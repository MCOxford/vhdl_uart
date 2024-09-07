:: ***************************************************************************
:: *        COMMAND LINE COMPATIBLE FPGA SIMULATION SCRIPT                                      *
:: *                                                                                                                                *
:: *                                                                                                                                *
:: ***************************************************************************

rd /S /Q ..\sim
mkdir ..\sim


:: ***************************************************************************
:: ********* Move to the simulation folder                                 ***
:: ***************************************************************************

:: Call the modelsim simulation with the command line and record the error status
cd ..\sim
call vsim %1 -do ..\\scripts\button_handler_sim.do

set SIM_ERR=%errorlevel%
echo Simulation Error Exit Code = %SIM_ERR%

:: Delete simulation waveform
del vsim.wlf

:: Move back to the script folder in case the simulation is to be repeated
cd ..\scripts

exit /B %SIM_ERR%