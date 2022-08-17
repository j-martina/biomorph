class BIO_ArcCaster : BIO_Weapon
{
	enum FireSpriteIndex : uint8
	{
		FIRE_SPRITE_B,
		FIRE_SPRITE_C,
		FIRE_SPRITE_D,
		FIRE_SPRITE_E
	};

	protected FireSpriteIndex FireSprite;

	Default
	{
		Tag "$BIO_ARCCASTER_TAG";
		
		Inventory.Icon 'ARCAZ0';
		Inventory.PickupMessage "$BIO_ARCCASTER_PKUP";

		Weapon.AmmoGive 40;
		Weapon.AmmoType 'Cell';
		Weapon.AmmoUse 1;
		Weapon.SlotNumber 6;
		Weapon.SlotPriority SLOTPRIO_HIGH;
		Weapon.ReadySound "bio/weap/arccaster/ready";

		BIO_Weapon.GraphQuality 6;
		BIO_Weapon.MagazineFlags BIO_MAGF_RECHARGING_1;
		BIO_Weapon.MagazineType 'BIO_RechargingMagazine';
		BIO_Weapon.MagazineSize 50;
		BIO_Weapon.OperatingMode 'BIO_OpMode_ArcCaster_Rapid';
		BIO_Weapon.PickupMessages
			"$BIO_ARCCASTER_PKUP",
			"$BIO_ARCCASTER_SCAV";
		BIO_Weapon.SpawnCategory BIO_WSCAT_PLASRIFLE;
		BIO_Weapon.Summary "$BIO_ARCCASTER_SUMM";
	}

	override void SetDefaults()
	{
		Pipelines.Push(
			BIO_WeaponPipelineBuilder.Create()
				.Rail('BIO_ElectricPuff',
					color2: "LightSteelBlue", flags: RGF_FULLBRIGHT, maxDiff: 30.0,
					range: 512.0, duration: 1, sparsity: 0.1, driftSpeed: 0.0
				)
				.X1D8Damage(4)
				.Spread(3.0, 3.0)
				.FireSound("bio/weap/arccaster/fire")
				.Build()
		);
	}

	override uint ModCost(uint base) const
	{
		return super.ModCost(base) * 2;
	}
}

// States: core.
extend class BIO_ArcCaster
{
	States
	{
	Spawn:
		ARCA Z 0;
		#### # 0 A_BIO_Spawn;
		Stop;
	Ready:
		ARCA A 1 A_WeaponReady(WRF_ALLOWRELOAD | WRF_ALLOWZOOM);
		Loop;
	Deselect:
		ARCA A 0 A_BIO_Deselect;
		Stop;
	Select:
		ARCA A 0 A_BIO_Select;
		Stop;
	Fire:
		TNT1 A 0 A_BIO_Op_Fire;
		Stop;
	Fire.B:
		ARCA B 2 Bright
		{
			A_BIO_SetFireTime(0);
			A_BIO_FireSound(CHAN_AUTO);
			A_BIO_ArcCaster_Fire(FIRE_SPRITE_C);
		}
		TNT1 A 0 A_BIO_Op_PostFire;
		TNT1 A 0 A_BIO_AutoReload;
		Goto Ready;
	Fire.C:
		ARCA C 2 Bright
		{
			A_BIO_SetFireTime(0);
			A_BIO_ArcCaster_Fire(FIRE_SPRITE_D);
		}
		TNT1 A 0 A_BIO_Op_PostFire;
		TNT1 A 0 A_BIO_AutoReload;
		Goto Ready;
	Fire.D:
		ARCA D 2 Bright
		{
			A_BIO_SetFireTime(0);
			A_BIO_ArcCaster_Fire(FIRE_SPRITE_E);
		}
		TNT1 A 0 A_BIO_Op_PostFire;
		TNT1 A 0 A_BIO_AutoReload;
		Goto Ready;
	Fire.E:
		ARCA E 2 Bright
		{
			A_BIO_SetFireTime(0);
			A_BIO_ArcCaster_Fire(FIRE_SPRITE_B);
		}
		TNT1 A 0 A_BIO_Op_PostFire;
		TNT1 A 0 A_BIO_AutoReload;
		Goto Ready;
	Flash:
		TNT1 A 2
		{
			A_BIO_SetFireTime(0);
			A_Light(Random(3, 7));
		}
		Goto LightDone;
	}
}

// Helper functions.
extend class BIO_ArcCaster
{
	protected action void A_BIO_ArcCaster_Fire(FireSpriteIndex fireSprite)
	{
		A_BIO_Fire();
		A_GunFlash();
		invoker.FireSprite = fireSprite;
	}
}

// Operating modes /////////////////////////////////////////////////////////////

class BIO_OpMode_ArcCaster_Rapid : BIO_OpMode_Rapid
{
	final override class<BIO_Weapon> WeaponType() const { return 'BIO_ArcCaster'; }

	final override void Init(readOnly<BIO_Weapon> weap)
	{
		FireTimeGroups.Push(weap.StateTimeGroupFrom('Fire.B'));
	}

	final override statelabel FireState() const
	{
		return 'Rapid.Fire';
	}
}

extend class BIO_ArcCaster
{
	States
	{
	Rapid.Fire:
		TNT1 A 0 A_BIO_CheckAmmo;
		TNT1 A 0
		{
			switch (invoker.FireSprite)
			{
			default:
			case FIRE_SPRITE_B: return ResolveState('Fire.B');
			case FIRE_SPRITE_C: return ResolveState('Fire.C');
			case FIRE_SPRITE_D: return ResolveState('Fire.D');
			case FIRE_SPRITE_E: return ResolveState('Fire.E');
			}
		}
		Stop;
	}
}
