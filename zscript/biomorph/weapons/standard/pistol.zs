class BIO_Pistol : BIO_Weapon
{
	Default
	{
		Obituary "$OB_MPPISTOL";
		Tag "$TAG_PISTOL";

		Inventory.Icon 'PISTA0';
		Inventory.PickupMessage "$BIO_PISTOL_PKUP";

		Weapon.AmmoGive 15;
		Weapon.AmmoType 'Clip';
		Weapon.AmmoUse 1;
		Weapon.SelectionOrder SELORDER_PISTOL;
		Weapon.SlotNumber 2;
		Weapon.SlotPriority SLOTPRIO_STANDARD;
		Weapon.UpSound "bio/weap/gunswap_0";

		BIO_Weapon.Flags BIO_WF_PISTOL | BIO_WF_ONEHANDED;
		BIO_Weapon.Grade BIO_GRADE_STANDARD;
		BIO_Weapon.MagazineSize 15;
		BIO_Weapon.MagazineType 'BIO_MAG_Pistol';
		BIO_Weapon.PlayerVisual BIO_PVIS_PISTOL;
		BIO_Weapon.SwitchSpeeds 14, 14;
		BIO_Weapon.ScavengePersist true;
	}

	override void InitPipelines(in out Array<BIO_WeaponPipeline> pipelines) const
	{
		pipelines.Push(BIO_WeaponPipelineBuilder.Create()
			.BasicBulletPipeline('BIO_Bullet', 1, 5, 15, 4.0, 2.0)
			.FireSound("bio/weap/pistol/fire")
			.AssociateFirstFireTime()
			.Build());
	}

	override void InitFireTimes(in out Array<BIO_StateTimeGroup> groups) const
	{
		groups.Push(StateTimeGroupFrom('Fire'));
	}

	override void InitReloadTimes(in out Array<BIO_StateTimeGroup> groups) const
	{
		groups.Push(StateTimeGroupFrom('Reload'));
	}

	States
	{
	Ready:
		PISG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	Deselect:
		PISG A 0 A_BIO_Deselect;
		Stop;
	Select:
		PISG A 0 A_BIO_Select;
		Stop;
	Fire:
		TNT1 A 0 A_BIO_CheckAmmo;
		PISG A 4 A_SetFireTime(0);
		PISG B 6 Bright
		{
			A_SetFireTime(1);
			A_BIO_Fire();
			A_GunFlash();
			A_FireSound();
			A_PresetRecoil('BIO_Recoil_Handgun');
		}
		PISG C 4 A_SetFireTime(2);
		PISG B 5
		{
			A_SetFireTime(3);
			A_ReFire();
		}
		TNT1 A 0 A_AutoReload;
		Goto Ready;
	Reload:
		// TODO: Reload sounds
		TNT1 A 0 A_JumpIf(!invoker.CanReload(), 'Ready');
		PISG A 1 A_WeaponReady(WRF_NOFIRE);
		PISG A 1 Fast Offset(0, 32 + 1) A_SetReloadTime(1);
		PISG A 1 Fast Offset(0, 32 + 3) A_SetReloadTime(2);
		PISG A 1 Fast Offset(0, 32 + 7) A_SetReloadTime(3);
		PISG A 1 Fast Offset(0, 32 + 15) A_SetReloadTime(4);
		PISG A 1 Offset(0, 32 + 30) A_SetReloadTime(5);
		PISG A 30 Offset(0, 32 + 30) A_SetReloadTime(6);
		PISG A 1 Offset(0, 32 + 15)
		{
			A_SetReloadTime(7);
			A_LoadMag();
		}
		PISG A 1 Fast Offset(0, 32 + 11) A_SetReloadTime(8);
		PISG A 1 Fast Offset(0, 32 + 7) A_SetReloadTime(9);
		PISG A 1 Fast Offset(0, 32 + 5) A_SetReloadTime(10);
		PISG A 1 Fast Offset(0, 32 + 3) A_SetReloadTime(11);
		PISG A 1 Fast Offset(0, 32 + 2) A_SetReloadTime(12);
		PISG A 1 Fast Offset(0, 32 + 1) A_SetReloadTime(13);
		Goto Ready;
	Flash:
		PISF A 7 Bright
		{
			A_SetFireTime(1, modifier: 1);
			A_Light(1);
		}
		Goto LightDone;
		PISF A 7 Bright
		{
			A_SetFireTime(1, modifier: 1);
			A_Light(1);
		}
		Goto LightDone;
	Spawn:
		PIST A 0;
		PIST A 0 A_BIO_Spawn;
		Stop;
	}
}

class BIO_EviternityPistol : BIO_Pistol
{
	final override void InitPipelines(in out Array<BIO_WeaponPipeline> pipelines) const
	{
		pipelines.Push(BIO_WeaponPipelineBuilder.Create()
			.Bullet()
			.X1D3Damage(5)
			.Spread(0.0, 0.0)
			.FireSound("bio/weap/pistol/fire")
			.Build());
	}

	States
	{
	Fire:
		TNT1 A 0 A_BIO_CheckAmmo;
		PISG A 1 A_SetFireTime(0);
		PISG B 3 Bright
		{
			A_SetFireTime(1);
			A_BIO_Fire();
			A_GunFlash();
			A_FireSound();
			A_PresetRecoil('BIO_Recoil_Handgun');
		}
		PISG C 3 A_SetFireTime(2);
		PISG B 3 A_SetFireTime(3);
		TNT1 A 0 A_ReFire;
		PISG A 4 A_SetFireTime(4);
		TNT1 A 0 A_AutoReload;
		Goto Ready;
	}
}

class BIO_ValiantPistol : BIO_Pistol
{
	final override void InitPipelines(in out Array<BIO_WeaponPipeline> pipelines) const
	{
		pipelines.Push(BIO_WeaponPipelineBuilder.Create()
			.Bullet()
			.X1D3Damage(5)
			.Spread(5.6, 0.0)
			.FireSound("bio/weap/pistol/fire")
			.Build());
	}

	States
	{
	Fire:
		TNT1 A 0 A_BIO_CheckAmmo;
		PISG C 3 A_SetFireTime(0);
		PISG D 3
		{
			A_SetFireTime(1);
			A_BIO_Fire();
			A_GunFlash();
			A_FireSound();
			A_PresetRecoil('BIO_Recoil_Handgun');
		}
		PISG E 3 A_SetFireTime(2);
		TNT1 A 0 A_ReFire();
		PISG B 2 Bright A_SetFireTime(3);
		TNT1 A 0 A_AutoReload;
		Goto Ready;
	}
}

class BIO_Mag_Pistol : Ammo { mixin BIO_Magazine; }
