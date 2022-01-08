enum BIO_FireFunctorCapabilities : uint8
{
	BIO_FFC_NONE = 0,
	BIO_FFC_PUFF = 1 << 0,
	BIO_FFC_PROJECTILE = 1 << 1,
	BIO_FFC_RAIL = 1 << 2,
	BIO_FFC_ALL = uint8.MAX
}

class BIO_FireFunctor play abstract
{
	abstract Actor Invoke(BIO_Weapon weap, in out BIO_FireData fireData) const;

	virtual void GetDamageValues(in out Array<int> vals) const {}
	virtual void SetDamageValues(in out Array<int> vals) {}

	uint DamageValueCount() const
	{
		Array<int> dmgVals;
		GetDamageValues(dmgVals);
		return dmgVals.Size();
	}

	// Output is fully localized.
	static string FireTypeTag(Class<Actor> fireType, uint count)
	{
		if (fireType is 'BIO_Projectile')
		{
			let defs = GetDefaultByType((Class<BIO_Projectile>)(fireType));

			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else if (fireType is 'BIO_FastProjectile')
		{
			let defs = GetDefaultByType((Class<BIO_FastProjectile>)(fireType));
		
			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else if (fireType is 'BIO_RailPuff')
		{
			let defs = GetDefaultByType((Class<BIO_RailPuff>)(fireType));

			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else if (fireType is 'BIO_RailSpawn')
		{
			let defs = GetDefaultByType((Class<BIO_RailSpawn>)(fireType));

			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else if (fireType is 'BIO_Puff')
		{
			let defs = GetDefaultByType((Class<BIO_Puff>)(fireType));

			switch (count)
			{
			case -1:
			case 1: return defs.GetTag();
			default: return StringTable.Localize(defs.PluralTag);
			}
		}
		else if (fireType is 'BIO_BFGExtra')
		{
			switch (count)
			{
			case -1:
			case 1: return StringTable.Localize("$BIO_PROJEXTRA_TAG_BFGRAY");
			default: return StringTable.Localize("$BIO_PROJEXTRA_TAG_BFGRAYS"); 
			}
		}
		else if (fireType == null)
			return StringTable.Localize("$BIO_NOTHING");
		else
			return StringTable.Localize(GetDefaultByType(fireType).GetTag());
	}

	abstract void ToString(
		in out Array<string> readout,
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const;

	// If a category of fire type can be handled by this functor, include its
	// bit. Used by affixes to determine if a new fire type may be compatible.
	abstract BIO_FireFunctorCapabilities Capabilities() const;

	readOnly<BIO_FireFunctor> AsConst() const { return self; }
}

class BIO_FireFunc_Projectile : BIO_FireFunctor
{
	double SpawnOffsXY;
	int SpawnHeight;

	override Actor Invoke(BIO_Weapon weap, in out BIO_FireData fireData) const
	{
		return weap.BIO_FireProjectile(fireData.FireType,
			angle: fireData.Angle + FRandom(-fireData.HSpread, fireData.HSpread),
			spawnOfs_xy: SpawnOffsXY, spawnHeight: SpawnHeight,
			pitch: fireData.Pitch + FRandom(-fireData.VSpread, fireData.VSpread));
	}

	BIO_FireFunc_Projectile CustomSet(double spawnOffs_xy, int spawnH)
	{
		SpawnOffsXY = spawnOffs_xy;
		SpawnHeight = spawnH;
		return self;
	}

	override void ToString(
		in out Array<string> readout,
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		uint fc = ppl.GetFireCount();
		Class<Actor> ft = ppl.GetFireType();

		readout.Push(String.Format(
			StringTable.Localize("$BIO_FIREFUNC_PROJECTILE"),
			BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
			ft != pplDef.GetFireType() ? CRESC_STATMODIFIED : CRESC_STATDEFAULT,
			FireTypeTag(ft, fc)));
	}

	override BIO_FireFunctorCapabilities Capabilities() const
	{
		return BIO_FFC_PROJECTILE;
	}
}

const BULLET_ALWAYS_SPREAD = -1;
const BULLET_ALWAYS_ACCURATE = 0;
const BULLET_FIRST_ACCURATE = 1;

class BIO_FireFunc_Bullet : BIO_FireFunctor
{
	private int AccuracyType, Flags;

	override Actor Invoke(BIO_Weapon weap, in out BIO_FireData fireData) const
	{
		return weap.BIO_FireBullet(fireData.HSpread, fireData.VSpread,
			AccuracyType, fireData.Damage, fireData.FireType, Flags);
	}

	void AlwaysSpread() { AccuracyType = BULLET_ALWAYS_SPREAD; }
	void AlwaysAccurate() { AccuracyType = BULLET_ALWAYS_ACCURATE; }
	void FirstAccurate() { AccuracyType = BULLET_FIRST_ACCURATE; }

	BIO_FireFunc_Bullet Setup(int accType = BULLET_ALWAYS_SPREAD, int flagArg = 0)
	{
		AccuracyType = accType;
		Flags = flagArg;
		return self;
	}

	override void ToString(
		in out Array<string> readout,
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		uint fc = ppl.GetFireCount();
		Class<Actor> ft = ppl.GetFireType();

		readout.Push(String.Format(
			StringTable.Localize("$BIO_FIREFUNC_PROJECTILE"),
			BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
			ft != pplDef.GetFireType() ? CRESC_STATMODIFIED : CRESC_STATDEFAULT,
			FireTypeTag(ft, fc)));
	}

	override BIO_FireFunctorCapabilities Capabilities() const
	{
		return BIO_FFC_PUFF;
	}
}

class BIO_FireFunc_Rail : BIO_FireFunctor
{
	color Color1, Color2;
	ERailFlags Flags;
	int ParticleDuration, SpiralOffset, PierceLimit;
	double MaxDiff, ParticleSparsity, ParticleDriftSpeed;

	override Actor Invoke(BIO_Weapon weap, in out BIO_FireData fireData) const
	{
		Class<Actor> puff_t = null, spawnClass = null;

		if (fireData.FireType is 'BIO_RailPuff')
		{
			puff_t = fireData.FireType;
			spawnClass = GetDefaultByType(
				(Class<BIO_RailPuff>)(fireData.FireType)).SpawnClass;
		}
		else if (fireData.FireType is 'BIO_RailSpawn')
		{
			spawnClass = fireData.FireType;
			puff_t = GetDefaultByType(
				(Class<BIO_RailSpawn>)(fireData.FireType)).PuffType;
		}

		weap.BIO_RailAttack(fireData.Damage,
			spawnOffs_xy: fireData.Angle,
			color1: Color1,
			color2: Color2,
			flags: Flags,
			maxDiff: MaxDiff,
			puff_t: puff_t,
			spread_xy: fireData.HSpread,
			spread_z: fireData.VSpread,
			duration: ParticleDuration,
			sparsity: ParticleSparsity,
			driftSpeed: ParticleDriftSpeed,
			spawnClass: spawnClass,
			spawnOffs_z: fireData.Pitch
		);

		return null;
	}

	BIO_FireFunc_Rail Setup(color color1 = 0, color color2 = 0,
		ERailFlags flags = RGF_NONE, double maxDiff = 0.0, int duration = 0,
		double sparsity = 1.0, double driftSpeed = 1.0, int spiralOffs = 270)
	{
		self.Color1 = color1;
		self.Color2 = color2;
		self.Flags = flags;
		self.MaxDiff = maxDiff;
		self.ParticleDuration = duration;
		self.ParticleSparsity = sparsity;
		self.ParticleDriftSpeed = driftSpeed;
		self.SpiralOffset = spiralOffs;

		return self;
	}

	override void ToString(
		in out Array<string> readout,
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		Class<Actor> ft = ppl.GetFireType(), puff_t = null, spawnClass = null;
		bool defaultPuff = true, defaultSpawn = true;
		uint fc = ppl.GetFireCount();

		if (ft is 'BIO_RailPuff')
		{
			puff_t = ft;
			spawnClass = GetDefaultByType((Class<BIO_RailPuff>)(ft)).SpawnClass;
			defaultPuff = puff_t == pplDef.GetFireType();
		}
		else if (ft is 'BIO_RailSpawn')
		{
			spawnClass = ft;
			puff_t = GetDefaultByType((Class<BIO_RailSpawn>)(ft)).PuffType;
			defaultSpawn = spawnClass == pplDef.GetFireType();
		}

		string output = "";

		if (puff_t != null && spawnClass != null)
		{
			output = String.Format(
				StringTable.Localize("$BIO_FIREFUNC_RAIL"),
				BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
				defaultPuff ? CRESC_STATDEFAULT : CRESC_STATMODIFIED,
				FireTypeTag(puff_t, fc),
				defaultSpawn ? CRESC_STATDEFAULT : CRESC_STATMODIFIED,
				FireTypeTag(spawnClass, fc));
		}
		else if (puff_t == null)
		{
			output = String.Format(
				StringTable.Localize("$BIO_FIREFUNC_RAIL_NOPUFF"),
				BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
				defaultSpawn ? CRESC_STATDEFAULT : CRESC_STATMODIFIED,
				FireTypeTag(spawnClass, fc));
		}
		else if (spawnClass == null)
		{
			output = String.Format(
				StringTable.Localize("$BIO_FIREFUNC_RAIL_NOSPAWN"),
				BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc,
				defaultPuff ? CRESC_STATDEFAULT : CRESC_STATMODIFIED,
				FireTypeTag(puff_t, fc));
		}
		else
		{
			output = String.Format(
				StringTable.Localize("$BIO_FIREFUNC_RAIL_NOTHING"),
				BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc);
		}

		readout.Push(output);
	}

	override BIO_FireFunctorCapabilities Capabilities() const
	{
		return BIO_FFC_RAIL;
	}
}

class BIO_FireFunc_Melee : BIO_FireFunctor abstract
{
	float Range, Lifesteal;
}

class BIO_FireFunc_Punch : BIO_FireFunc_Melee
{
	ECustomPunchFlags Flags;
	sound HitSound, MissSound;

	override Actor Invoke(BIO_Weapon weap, in out BIO_FireData fireData) const
	{
		return weap.BIO_Punch(fireData, Range, Lifesteal, HitSound, MissSound, Flags);
	}

	override void ToString(
		in out Array<string> readout,
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		readout.Push(StringTable.Localize("$BIO_FIREFUNC_PUNCH"));
	}

	override BIO_FireFunctorCapabilities Capabilities() const
	{
		return BIO_FFC_PUFF;
	}
}

class BIO_FireFunc_Saw : BIO_FireFunc_Melee
{
	ESawFlags Flags;
	sound FullSound, HitSound;

	override Actor Invoke(BIO_Weapon weap, in out BIO_FireData fireData) const
	{
		weap.BIO_Saw(FullSound, HitSound, fireData.Damage,
			fireData.FireType, Flags, Range, Lifesteal);
		return null;
	}

	override void ToString(
		in out Array<string> readout,
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		readout.Push(StringTable.Localize("$BIO_FIREFUNC_SAW"));
	}

	override BIO_FireFunctorCapabilities Capabilities() const
	{
		return BIO_FFC_PUFF;
	}
}

class BIO_FireFunc_BFGSpray : BIO_FireFunctor
{
	final override Actor Invoke(BIO_Weapon weap, in out BIO_FireData fireData) const
	{
		return weap.BIO_BFGSpray(fireData);
	}

	final override void ToString(
		in out Array<string> readout,
		readOnly<BIO_WeaponPipeline> ppl,
		readOnly<BIO_WeaponPipeline> pplDef) const
	{
		uint fc = ppl.GetFireCount();
		Class<Actor> ft = ppl.GetFireType();

		readout.Push(String.Format(
			StringTable.Localize("$BIO_FIREFUNC_BFGSPRAY"),
			BIO_Utils.StatFontColor(fc, pplDef.GetFireCount()), fc));
	}

	final override BIO_FireFunctorCapabilities Capabilities() const
	{
		return BIO_FFC_NONE;
	}
}
