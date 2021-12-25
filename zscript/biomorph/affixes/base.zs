class BIO_Affix play abstract
{
	const CRESC_POSITIVE = "\cd"; // Green
	const CRESC_NEGATIVE = "\cg"; // Red
	const CRESC_NEUTRAL = "\cc"; // Grey
	const CRESC_MIXED = "\cf"; // Gold

	// Output should be fully localized.
	abstract string GetTag() const;
}

enum BIO_WeaponAffixFlags : uint
{
	BIO_WAF_NONE = 0,
	BIO_WAF_FIREFUNC = 1 << 0,
	BIO_WAF_FIRETYPE = 1 << 1,
	BIO_WAF_FIRECOUNT = 1 << 2,
	BIO_WAF_DAMAGE = 1 << 3,
	BIO_WAF_ACCURACY = 1 << 4,
	BIO_WAF_ONPROJFIRED = 1 << 5,
	BIO_WAF_ONPUFFFIRED = 1 << 6,
	BIO_WAF_PROJSPEED = 1 << 7,
	BIO_WAF_PROJACCEL = 1 << 8,
	BIO_WAF_FIRETIME = 1 << 9,
	BIO_WAF_RELOADTIME = 1 << 10,
	BIO_WAF_MAGSIZE = 1 << 11,
	BIO_WAF_MAGAZINE = 1 << 12, // Adds or removes rounds
	BIO_WAF_ALERT = 1 << 13,
	BIO_WAF_SWITCHSPEED = 1 << 14,
	BIO_WAF_KICKBACK = 1 << 15,
	BIO_WAF_CRIT = 1 << 16,
	BIO_WAF_LIFESTEAL = 1 << 17,
	BIO_WAF_MELEERANGE = 1 << 18,
	BIO_WAF_ONKILL = 1 << 19,
	BIO_WAF_ALL = uint.MAX
}

class BIO_WeaponAffix : BIO_Affix abstract
{
	abstract bool Compatible(readOnly<BIO_Weapon> weap) const;
	virtual void Init(readOnly<BIO_Weapon> weap) {}
	virtual void CustomInit(readOnly<BIO_Weapon> weap, Dictionary dict)
	{
		Console.Printf(Biomorph.LOGPFX_INFO ..
			"Weapon affix %s has no custom initialiser.", GetClassName());
	}
	virtual void Apply(BIO_Weapon weap) const {}

	virtual void OnTick(BIO_Weapon weap) {}

	// Modify only the fire count or the critical flag here;
	// everything else gets overwritten afterwards.
	virtual void BeforeAllFire(BIO_Weapon weap, in out BIO_FireData fireData) const {}
	
	// Modifying `FireCount` here does nothing, since it is overwritten afterwards.
	virtual void BeforeEachFire(BIO_Weapon weap, in out BIO_FireData fireData) const {}

	virtual void OnTrueProjectileFired(BIO_Weapon weap,
		BIO_Projectile proj) const {}	
	virtual void OnFastProjectileFired(BIO_Weapon weap,
		BIO_FastProjectile proj) const {}
	virtual void OnPuffFired(BIO_Weapon weap,
		BIO_Puff puff) const {}

	virtual void OnKill(BIO_Weapon weap, Actor killed, Actor inflictor) const {}
	virtual void OnCriticalShot(BIO_Weapon weap, in out BIO_FireData fireData) const {}

	virtual void OnPickup(BIO_Weapon weap) const {}
	virtual void OnMagLoad(BIO_Weapon weap, bool secondary, in out int diff) const {}
	virtual void OnDrop(BIO_Weapon weap, BIO_Player dropper) const {}

	virtual bool CanGenerate() const { return true; }
	virtual bool CanGenerateImplicit() const { return false; }

	abstract void ToString(in out Array<string> strings,
		readOnly<BIO_Weapon> weap) const;
	abstract BIO_WeaponAffixFlags GetFlags() const;
}

class BIO_EquipmentAffix : BIO_Affix abstract
{
	abstract void Init(readOnly<BIO_Equipment> equip);
	abstract bool Compatible(readOnly<BIO_Equipment> equip) const;

	virtual void OnEquip(BIO_Equipment equip) const {}
	virtual void OnUnequip(BIO_Equipment equip, bool broken) const {}
	virtual void PreArmorApply(BIO_Armor armor, in out BIO_ArmorData stats) const {}

	virtual void OnDamageTaken(BIO_Equipment equip, Actor inflictor,
		Actor source, in out int damage, name dmgType) const {}

	// Output should be fully localized.
	abstract void ToString(in out Array<string> strings,
		readOnly<BIO_Equipment> equip) const;
}
