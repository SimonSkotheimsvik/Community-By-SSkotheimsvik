Tool to collect hardware has from computer and import to Autopilot.

1. Unbox the device and boot it up
2. At the first OOBE picture, press SHIFT+F10 to start CMD
3. Insert USB and CD to D:
	Use the following to locate the disk if D is incorrect:
	wmic logicaldisk list brief
4. Decide if you need to delete compHash.csv
5. Run GetAutoPilot.cmd
	Make your choices
6. Tur of the PC (shutdown /s /t 0)
7. Import compHash.csv to Autopilot in Intune
8. Let the device register and assign a profile before booting the device to Autopilot.

2020.05.08 - v1.0 - Simon
2020.09.30 - v1.1 - Simon