enum BIO_WeaponFlags : uint16
{
	BIO_WF_NONE = 0,
	// More frequently-changing state
	BIO_WF_ZOOMED = 1 << 0,
	// Less frequently-changing state
	BIO_WF_CORRUPTED = 1 << 1,
	BIO_WF_AFFIXESHIDDEN = 1 << 2, // Caused by corruption
	BIO_WF_ONEHANDED = 1 << 3,
	BIO_WF_PISTOL = 1 << 4,
	BIO_WF_SHOTGUN = 1 << 5,
	// The following 3 are applicable only to dual-wielded weapons
	BIO_WF_NOAUTOPRIMARY = 1 << 13,
	BIO_WF_NOAUTOSECONDARY = 1 << 14,
	BIO_WF_AKIMBORELOAD = 1 << 15,
	BIO_WF_ALL = uint16.MAX
}

extend class BIO_NewWeapon
{
	const MAX_AFFIXES = 6;

	// SelectionOrder is for when ammo runs out; lower number, higher priority

	const SELORDER_PLASRIFLE = 100;
	const SELORDER_PLASRIFLE_SURP = SELORDER_PLASRIFLE + 20;
	const SELORDER_PLASRIFLE_STD = SELORDER_PLASRIFLE - 20;
	const SELORDER_PLASRIFLE_SPEC = SELORDER_PLASRIFLE - 40;
	const SELORDER_PLASRIFLE_CLSF = SELORDER_PLASRIFLE - 60;

	const SELORDER_SSG = 400;
	const SELORDER_SSG_SURP = SELORDER_SSG + 20;
	const SELORDER_SSG_STD = SELORDER_SSG - 20;
	const SELORDER_SSG_SPEC = SELORDER_SSG - 40;
	const SELORDER_SSG_CLSF = SELORDER_SSG - 60;

	const SELORDER_CHAINGUN = 700;
	const SELORDER_CHAINGUN_SURP = SELORDER_CHAINGUN + 20;
	const SELORDER_CHAINGUN_STD = SELORDER_CHAINGUN - 20;
	const SELORDER_CHAINGUN_SPEC = SELORDER_CHAINGUN - 40;
	const SELORDER_CHAINGUN_CLSF = SELORDER_CHAINGUN - 60;

	const SELORDER_SHOTGUN = 1300;
	const SELORDER_SHOTGUN_SURP = SELORDER_SHOTGUN + 20;
	const SELORDER_SHOTGUN_STD = SELORDER_SHOTGUN - 20;
	const SELORDER_SHOTGUN_SPEC = SELORDER_SHOTGUN - 40;
	const SELORDER_SHOTGUN_CLSF = SELORDER_SHOTGUN - 60;

	const SELORDER_PISTOL = 1900;
	const SELORDER_PISTOL_SURP = SELORDER_PISTOL + 20;
	const SELORDER_PISTOL_STD = SELORDER_PISTOL - 20;
	const SELORDER_PISTOL_SPEC = SELORDER_PISTOL - 40;
	const SELORDER_PISTOL_CLSF = SELORDER_PISTOL - 60;

	const SELORDER_CHAINSAW = 2200;
	const SELORDER_CHAINSAW_SURP = SELORDER_CHAINSAW + 20;
	const SELORDER_CHAINSAW_STD = SELORDER_CHAINSAW - 20;
	const SELORDER_CHAINSAW_SPEC = SELORDER_CHAINSAW - 40;
	const SELORDER_CHAINSAW_CLSF = SELORDER_CHAINSAW - 60;

	const SELORDER_RLAUNCHER = 2500;
	const SELORDER_RLAUNCHER_SURP = SELORDER_RLAUNCHER + 20;
	const SELORDER_RLAUNCHER_STD = SELORDER_RLAUNCHER - 20;
	const SELORDER_RLAUNCHER_SPEC = SELORDER_RLAUNCHER - 40;
	const SELORDER_RLAUNCHER_CLSF = SELORDER_RLAUNCHER - 60;

	const SELORDER_BFG = 2800;
	const SELORDER_BFG_SURP = SELORDER_BFG + 20;
	const SELORDER_BFG_STD = SELORDER_BFG - 20;
	const SELORDER_BFG_SPEC = SELORDER_BFG - 40;
	const SELORDER_BFG_CLSF = SELORDER_BFG - 60;

	const SELORDER_FIST = 3700;

	// SlotPriority is for manual selection; higher number, higher priority

	const SLOTPRIO_MAX = 1.0;

	const SLOTPRIO_CLASSIFIED_UNIQUE = SLOTPRIO_CLASSIFIED + 0.1;
	const SLOTPRIO_CLASSIFIED = 0.8;

	const SLOTPRIO_SPECIALTY_UNIQUE = SLOTPRIO_SPECIALTY + 0.1;
	const SLOTPRIO_SPECIALTY = 0.6;

	const SLOTPRIO_STANDARD_UNIQUE = SLOTPRIO_STANDARD + 0.1;
	const SLOTPRIO_STANDARD = 0.4;

	const SLOTPRIO_SURPLUS_UNIQUE = SLOTPRIO_SURPLUS + 0.1;
	const SLOTPRIO_SURPLUS = 0.2;

	const SLOTPRIO_MIN = 0.0;

	// (RAT: Who designed those two properties to be so counter-intuitive?)
}
