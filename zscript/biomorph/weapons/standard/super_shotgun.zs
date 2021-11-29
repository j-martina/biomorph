class BIO_SuperShotgun : BIO_Weapon replaces SuperShotgun
{
	Default
	{
		Obituary "$OB_MPSSHOTGUN";
		Tag "$TAG_SUPERSHOTGUN";

		Inventory.Icon 'SGN2A0';
		Inventory.PickupMessage "$BIO_WEAP_PKUP_SUPERSHOTGUN";

		Weapon.AmmoGive 8;
		Weapon.AmmoType1 'Shell';
		Weapon.AmmoUse1 1;
		Weapon.SelectionOrder SELORDER_SSG;
		Weapon.SlotNumber 3;
		Weapon.SlotPriority SLOTPRIO_STANDARD;
		Weapon.UpSound "bio/weap/gunswap";

		BIO_Weapon.Flags BIO_WF_SHOTGUN;
		BIO_Weapon.Grade BIO_GRADE_STANDARD;
		BIO_Weapon.MagazineSize 2;
		BIO_Weapon.MagazineType 'BIO_MAG_SuperShotgun';
	}

	override void InitPipelines(in out Array<BIO_WeaponPipeline> pipelines) const
	{
		pipelines.Push(BIO_WeaponPipelineBuilder.Create(GetClass())
			.BasicProjectilePipeline('BIO_ShotPellet', 7, 5, 15, 12.0, 7.5)
			.AppendToFireFunctorString(" \c[Yellow]" ..
				StringTable.Localize("$BIO_PER_BARREL"))
			.FireSound("weapons/sshotf")
			.Build());
	}

	override void InitFireTimes(in out Array<BIO_StateTimeGroup> groups) const
	{
		groups.Push(BIO_StateTimeGroup.FromState(ResolveState('Fire.Single')));
	}

	override void InitReloadTimes(in out Array<BIO_StateTimeGroup> groups) const
	{
		groups.Push(BIO_StateTimeGroup.FromState(ResolveState('Reload')));
	}

	States
	{
	Ready:
		SHT2 A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;
	Deselect:
		SHT2 A 0 A_BIO_Deselect;
		Stop;
	Select:
		SHT2 A 0 A_BIO_Select;
		Stop;
	Fire:
		TNT1 A 0
		{
			if (BIO_CVar.MultiBarrelPrimary(Player))
				return ResolveState('Fire.Double');
			else
				return ResolveState('Fire.Single');
		}
	AltFire:
		TNT1 A 0
		{
			invoker.bAltFire = false;
			if (BIO_CVar.MultiBarrelPrimary(Player))
				return ResolveState('Fire.Single');
			else
				return ResolveState('Fire.Double');
		}
	Fire.Single:
		TNT1 A 0 A_AutoReload;
		SHT2 A 3 A_SetFireTime(0);
		SHT2 A 7 Bright
		{
			A_SetFireTime(1);
			A_BIO_Fire(spreadFactor: 0.5);
			A_PresetRecoil('BIO_Recoil_Shotgun');
			Player.SetPSprite(PSP_FLASH, invoker.FindState('Flash'), true);
			// TODO: Replace with a smaller sound
			A_FireSound();
		}
		Goto Ready;
	Fire.Double:
		TNT1 A 0 A_AutoReload(single: true, min: 2);
		SHT2 A 3 A_SetFireTime(0);
		SHT2 A 7 Bright
		{
			A_SetFireTime(1);
			A_BIO_Fire(fireFactor: 2);
			A_PresetRecoil('BIO_Recoil_SuperShotgun');
			Player.SetPSprite(PSP_FLASH, invoker.FindState('Flash'), true);
			A_FireSound();
		}
		Goto Ready;
	Reload:
		TNT1 A 0 A_JumpIf(!invoker.CanReload(), 'Ready');
		SHT2 B 7 A_SetReloadTime(0);
		SHT2 C 7
		{
			A_SetReloadTime(1);
			A_CheckReload();
		}
		SHT2 D 7
		{
			A_SetReloadTime(2);
			A_OpenShotgun2();
		}
		SHT2 E 7 A_SetTics(3);
		SHT2 F 7
		{
			A_SetReloadTime(4);
			A_LoadMag();
			A_LoadShotgun2();
		}
		SHT2 G 6 A_SetTics(5);
		SHT2 H 6
		{
			A_SetReloadTime(6);
			A_CloseShotgun2();
		}
		SHT2 A 5
		{
			A_SetReloadTime(7);
			A_ReFire();
		}
		Goto Ready;
	Flash:
		SHT2 I 4 Bright A_Light(1);
		SHT2 J 3 Bright A_Light(2);
		Goto LightDone;
	Spawn:
		SGN2 A 0;
		SGN2 A 0 A_BIO_Spawn;
		Stop;
	}
}

class BIO_MAG_SuperShotgun : Ammo { mixin BIO_Magazine; }