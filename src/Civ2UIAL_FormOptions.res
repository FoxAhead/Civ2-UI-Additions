        ��  ��                  3  4   ��
 F O R M O P T I O N S       0           <?xml version="1.0"?>
<options>
	<section name="UI Additions" description="User Interface Additions">
		<boolean key="UIAEnable" name="Enable" description="Enable patches from User Interface Additions
Features added:
 - Mouse wheel support wherever possible
 - Ability to choose any unit in stack beyond limit of 9
 - Work counter for Settlers/Engineers is displayed
 - Click-bounds of specialists sprites corrected in city screen
 - Number of the game turn is displayed
 - Current research numbers are displayed in Science Advisor
 - 64 bit patch included
 - CD Audio: correct looping and progress display"/>
	</section>
	<section name="civ2patch" description="Some fixes and enhacements from civ2patch project">
		<boolean key="civ2patchEnable" name="Enable" description="Enable patches from civ2patch">
			<boolean key="DisableCDCheckOn" name="Disable CD Check" description="When enabled, allow the application to run without the game CD."/>
			<boolean key="HostileAiOn" name="Hostile AI" description="When enabled, AI will not be unreasonably hostile to the player."/>
			<boolean key="RetirementYearOn" name="Retirement year" description="When enabled, allow the retirement year to be modified.">
				<integer key="RetirementWarningYear" name="Warning year"/>
				<integer key="RetirementYear" name="Retirement year"/>
			</boolean>
			<boolean key="PopulationLimitOn" name="Population limit" description="When enabled, allow the population limit to be modified.">
				<integer key="PopulationLimit" name="Population limit"/>
			</boolean>
			<boolean key="GoldLimitOn" name="Gold limit" description="When enabled, allow the gold limit to be modified.">
				<integer key="GoldLimit" name="Gold limit"/>
			</boolean>
			<boolean key="MapSizeLimitOn" name="Map size limit" description="When enabled, allow the number of map tiles limit to be modified.">
				<integer key="MapXLimit" name="Map X limit"/>
				<integer key="MapYLimit" name="Map Y limit"/>
				<integer key="MapSizeLimit" name="Map size limit"/>
			</boolean>
		</boolean>
	</section>
</options> 