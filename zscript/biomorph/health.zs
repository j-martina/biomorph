/* 	Health pickups run relevant player pawn callbacks.

	If Zhs2's Intelligent Supplies is installed, these behaviors are only invoked
	after these items have been fully drained.
*/

class BIO_HealthBonus : HealthBonus replaces HealthBonus
{
	Default
	{
		Inventory.PickupMessage "$BIO_HEALTHBONUS_PKUP";
	}

	final override void DoPickupSpecial(Actor toucher)
	{
		super.DoPickupSpecial(toucher);

		let bioPlayer = BIO_Player(toucher);
		if (bioPlayer == null) return;

		bioPlayer.OnHealthPickup(self);
	}
}

mixin class BIO_Health
{
	final override void DoPickupSpecial(Actor toucher)
	{
		super.DoPickupSpecial(toucher);

		let bioPlayer = BIO_Player(toucher);
		if (bioPlayer == null) return;

		bool zhs2IS = BIO_Utils.IntelligentSupplies();

		if (!zhs2IS || Amount <= 0)
			bioPlayer.OnHealthPickup(self);
	}
}

class BIO_Stimpack : Stimpack replaces Stimpack
{
	mixin BIO_Health;

	Default
	{
		Inventory.PickupMessage "$BIO_STIMPACK_PKUP";
		Health.LowMessage 25, "$BIO_STIMPACK_PKUPLOW";
	}
}

class BIO_Medikit : Medikit replaces Medikit
{
	mixin BIO_Health;

	Default
	{
		Inventory.PickupMessage "$BIO_MEDIKIT_PKUP";
		Health.LowMessage 25, "$BIO_MEDIKIT_PKUPLOW";
	}
}

class BIO_Soulsphere : Soulsphere replaces Soulsphere
{
	mixin BIO_Health;

	Default
	{
		Inventory.PickupMessage "$BIO_SOULSPHERE_PKUP";
		Health.LowMessage 25, "$BIO_SOULSPHERE_PKUPLOW";
	}
}

class BIO_Megasphere : Megasphere replaces Megasphere
{
	Default
	{
		Inventory.PickupMessage "$BIO_MEGASPHERE_PKUP";
	}

	States
	{
	Pickup:
		TNT1 A 0;
		Stop;
	}

	final override void DoPickupSpecial(Actor toucher)
	{
		super.DoPickupSpecial(toucher);
		toucher.GiveBody(-200);

		let bioPlayer = BIO_Player(toucher);
		if (bioPlayer == null) return;
		
		if (bioPlayer.EquippedArmor != null && bioPlayer.EquippedArmor.Reparable())
		{
			BIO_ArmorBonus.TryRepairArmor(bioPlayer, 0);

			PrintPickupMessage(toucher.CheckLocalView(), String.Format(
				StringTable.Localize("$BIO_MEGASPHERE_ARMORREPAIR"),
				bioPlayer.EquippedArmor.GetTag()));
		}
		else
		{
			bioPlayer.GiveInventory('BlueArmorForMegasphere', 1);

			PrintPickupMessage(toucher.CheckLocalView(),
				StringTable.Localize("$BIO_MEGASPHERE_SPIRITARMOR"));
		}

		bioPlayer.OnHealthPickup(self);
	}
}
