class BIO_SalvoLauncher : BIO_Weapon
{
	int FireTime1, FireTime2, FireTime3, FireTime4;
	property FireTimes: FireTime1, FireTime2, FireTime3, FireTime4;

	Default
	{
		+WEAPON.NOAUTOFIRE

		Tag "$BIO_WEAP_TAG_SALVOLAUNCHER";
		
		Inventory.Icon "SALVX0";
		Inventory.PickupMessage "$BIO_WEAP_PICKUP_SALVOLAUNCHER";

		Weapon.AmmoGive 20;
		Weapon.AmmoType "RocketAmmo";
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder 1600;
		Weapon.SlotNumber 5;

		BIO_Weapon.AffixMask BIO_WAM_SECONDARY | BIO_WAM_MAGSIZE | BIO_WAM_RELOADTIME;
		BIO_Weapon.Grade BIO_GRADE_EXPERIMENTAL;
		BIO_Weapon.DamageRange 30, 180;
		BIO_Weapon.FireType "BIO_Rocket";
		BIO_Weapon.MagazineType "RocketAmmo";
		BIO_Weapon.Spread 0.2, 0.2;

		BIO_SalvoLauncher.FireTimes 2, 2, 2, 10;
	}

	States
	{
	Ready:
		SALV A 1 A_WeaponReady;
		Loop;
	Deselect.Loop:
		SALV A 1 A_BIO_Lower;
		Loop;
	Select.Loop:
		SALV A 1 A_BIO_Raise;
		Loop;
	Fire:
		#### # 0 A_JumpIf(invoker.MagazineEmpty(), "Ready");
		SALV A 2 Offset(0, 32 + 3) A_SetTics(invoker.FireTime1);
		SALV B 2 Offset(0, 32 + 6)
		{
			A_SetTics(invoker.FireTime2);
			A_BIO_Fire();
		}
		SALV C 1 Offset(0, 32 + 9);
		SALV D 1 Offset(0, 32 + 12);
		SALV C 1 Offset(0, 32 + 9);
		SALV B 2 Offset(0, 32 + 6) A_SetTics(invoker.FireTime3);
		#### # 0 A_JumpIf(invoker.MagazineEmpty(), "Ready");
		SALV A 2 Offset(0, 32 + 3) A_SetTics(invoker.FireTime1);
		SALV B 2 Offset(0, 32 + 6)
		{
			A_SetTics(invoker.FireTime2);
			A_BIO_Fire();
		}
		SALV C 1 Offset(0, 32 + 9);
		SALV D 1 Offset(0, 32 + 12);
		SALV C 1 Offset(0, 32 + 9);
		SALV B 2 Offset(0, 32 + 6) A_SetTics(invoker.FireTime3);
		#### # 0 A_JumpIf(invoker.MagazineEmpty(), "Ready");
		SALV A 2 Offset(0, 32 + 3) A_SetTics(invoker.FireTime1);
		SALV B 2 Offset(0, 32 + 6)
		{
			A_SetTics(invoker.FireTime2);
			A_BIO_Fire();
		}
		SALV C 1 Offset(0, 32 + 9);
		SALV D 1 Offset(0, 32 + 12);
		SALV C 1 Offset(0, 32 + 9);
		SALV B 2 Offset(0, 32 + 6) A_SetTics(invoker.FireTime3);
		SALV A 10 A_SetTics(invoker.FireTime4);
		#### # 0 A_ReFire;
		Goto Ready;
	AltFire:
		TNT1 A 0 A_JumpIf(invoker.MagazineEmpty(), "Ready");
		SALV B 3 Offset(0, 32 + 6)
		{
			A_SetTics(invoker.FireTime1 + 1);
			invoker.bAltFire = false;
			A_BIO_Fire();
		}
		SALV C 3 Offset(0, 32 + 9) A_SetTics(invoker.FireTime2 + 1);
		SALV D 3 Offset(0, 32 + 12) A_SetTics(invoker.FireTime3 + 1);
		SALV C 3 Offset(0, 32 + 9) A_SetTics(invoker.FireTime3 + 1);
		SALV B 3 Offset(0, 32 + 6) A_SetTics(invoker.FireTime2 + 1);
		SALV A 3 Offset(0, 32 + 3) A_SetTics(invoker.FireTime1 + 1);
		// For some reason, NOAUTOFIRE blocks holding down AltFire.
		TNT1 A 0 A_JumpIf(Player.Cmd.Buttons & BT_ALTATTACK, "AltFire");
		Goto Ready;
	Spawn:
		SALV X -1;
		Stop;
	}

	override void OnTrueProjectileFired(BIO_Projectile proj)
	{
		proj.bForceRadiusDmg = true;
	}

	override void OnFastProjectileFired(BIO_FastProjectile proj)
	{
		proj.bForceRadiusDmg = true;
	}

	override void GetFireTimes(in out Array<int> fireTimes, bool _) const
	{
		fireTimes.PushV(FireTime1, FireTime2, FireTime3, FireTime4);
	}

	override void SetFireTimes(Array<int> fireTimes, bool _)
	{
		FireTime1 = fireTimes[0];
		FireTime2 = fireTimes[1];
		FireTime3 = fireTimes[2];
		FireTime4 = fireTimes[3];
	}

	override void GetReloadTimes(in out Array<int> _, bool _) const {}
	override void SetReloadTimes(Array<int> _, bool _) {}

	override void ResetStats()
	{
		super.ResetStats();

		FireTime1 = Default.FireTime1;
		FireTime2 = Default.FireTime2;
		FireTime3 = Default.FireTime3;
		FireTime4 = Default.FireTime4;
	}

	override void StatsToString(in out Array<string> stats) const
	{
		stats.Push(GenericFireDataReadout());

		string crEsc_burst = "", crEsc_auto = "";
		int tbft = TotalBurstFireTime(), tbft_def = Default.TotalBurstFireTime();
		int taft = TotalAutoFireTime(), taft_def = Default.TotalAutoFireTime();

		if (tbft > tbft_def)
			crEsc_burst = CRESC_STATWORSE;
		else if (tbft < tbft_def)
			crEsc_burst = CRESC_STATBETTER;
		else
			crEsc_burst = CRESC_STATDEFAULT;

		if (taft > taft_def)
			crEsc_auto = CRESC_STATWORSE;
		else if (taft < taft_def)
			crEsc_auto = CRESC_STATBETTER;
		else
			crEsc_auto = CRESC_STATDEFAULT;

		stats.Push(String.Format(StringTable.Localize("$BIO_WEAPSTAT_FIRETIME_BURST"),
			crEsc_burst, float(tbft) / 35.0));

		stats.Push(String.Format(StringTable.Localize("$BIO_WEAPSTAT_FIRETIME_AUTO"),
			crEsc_auto, float(taft) / 35.0));
	}

	override int DefaultFireTime() const
	{
		return
			Default.FireTime1 + Default.FireTime2 +
			Default.FireTime3 + Default.FireTime4;
	}

	protected int TotalBurstFireTime() const
	{
		return (FireTime1 * 3) + (FireTime2 * 3) + (FireTime3 * 3) + FireTime4;
	}

	protected int TotalAutoFireTime() const
	{
		return
			((FireTime1 + 1) * 2) +
			((FireTime2 + 1) * 2) +
			((FireTime3 + 1) * 2);
	}
}
