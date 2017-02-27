# jeti

Note:
- each turbine type has its own config file, saves memory and allows for heavy user configuration. look at the pbs.jsn example
- We have to generate audio files for all statuses, and map the audio files in the config for each turbine- suggestion that critical statuses is male voice, and information is female (I don’t have time for this now, please do it if you have time)
- All other turbine config files has to be changed to same format as pbs.jsn example (I don’t have time for this now, please do it if you have time)
- All config files must have set statusrunning, statusflameout, and (alarm, audio, stick, haptic) for every turbine status (quite a big job, but will set the standard for how this is done)

New
- Alarms (preconfigured best practise, only enabled after turbine status has been running  and not shut off by a user selectable switch (I need this myself) to not get annoying alarms during startup. This is fully automatic
- All negative statuses gives a message box (which is logged)
- Possible to enable audio on each status change
- Possible to enable alarms as defined in config file, with audio and haptic feedback
- OnScreen alarm on all negative values
- OnScreen alarm when turbine has started

- Configuration file pr turbine with advanced options pr status
On every status
— Textual mapping of status
— If it should be used when alarms are enabled
— Haptic feedback of left or right stick and type of vibration
— Audio announcement of status
— OnScreen announcement of alarm)

NOTE: This is considered beta, features not tested in real life yet.
