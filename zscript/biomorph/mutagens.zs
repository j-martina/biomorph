// Inventory bar items for modifying the affixes on gear (primarily weapons).

class BIO_Mutagen : Inventory abstract
{
	const DROPWT_RESET = 24;
	const DROPWT_ADD = 12;
	const DROPWT_RANDOM = 50;
	const DROPWT_REROLL = 10;
	const DROPWT_REMOVE = 24;
	const DROPWT_UPGRADE = 25;
	const DROPWT_RECYCLE = 12;
	const DROPWT_CORR = 3;

	meta uint DropWeight; property DropWeight: DropWeight;
	meta bool WorksOnUniques; property WorksOnUniques: WorksOnUniques;
	meta bool NoLoot; property NoLoot: NoLoot;

	Default
    {
		-COUNTITEM
		+DONTGIB
		+INVENTORY.INVBAR

		Height 16;
        Radius 20;

		Inventory.InterHubAmount 9999;
        Inventory.MaxAmount 9999;

		BIO_Mutagen.DropWeight 0;
		BIO_Mutagen.WorksOnUniques false;
		BIO_Mutagen.NoLoot false;
    }

	// Provides preliminary checks, and prints failure messaging.
	override bool Use(bool pickup)
	{
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);
		if (weap == null)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_NULLWEAP", 4.0);
			return false;
		}

		if (weap.BIOFlags & BIO_WF_CORRUPTED)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_CORRUPTED");
			return false;
		}

		if (!WorksOnUniques && weap.Rarity == BIO_RARITY_UNIQUE)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_UNIQUE", 4.0);
			return false;
		}

		return true;
	}

	readOnly<BIO_Mutagen> AsConst() const { return self; }
}

class BIO_Muta_Reset : BIO_Mutagen
{
	Default
	{
		Tag "$BIO_MUTA_RESET_TAG";
		Inventory.Icon 'MUREA0';
		Inventory.PickupMessage "$BIO_MUTA_RESET_PKUP";
		Inventory.UseSound "bio/muta/use/undo";
		BIO_Mutagen.DropWeight DROPWT_RESET;
	}

	States
	{
	Spawn:
		MURE A 6;
		---- A 6 Bright Light("BIO_Muta_Reset");
		Loop;
	}

	final override bool Use(bool pickup)
	{
		if (!super.Use(pickup)) return false;
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);

		if (weap.Affixes.Size() < 1)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_NOAFFIXES", 4.0);
			return false;
		}

		weap.ClearAffixes();
		weap.OnChange();
		Owner.A_Print("$BIO_MUTA_RESET_USE");
		return true;
	}
}

class BIO_Muta_Add : BIO_Mutagen
{
	Default
	{
		Tag "$BIO_MUTA_ADD_TAG";
		Inventory.Icon 'MUADA0';
		Inventory.PickupMessage "$BIO_MUTA_ADD_PKUP";
		Inventory.UseSound "bio/muta/use/general";
		BIO_Mutagen.DropWeight DROPWT_ADD;
	}

	States
	{
	Spawn:
		MUAD A 6;
		---- A 6 Bright Light("BIO_Muta_Add");
		Loop;
	}

	final override bool Use(bool pickup)
	{
		if (!super.Use(pickup)) return false;
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);

		if (weap.FullOnAffixes())
		{
			Owner.A_Print("$BIO_MUTA_FAIL_MAXAFFIXES", 4.0);
			return false;
		}

		if (!weap.AddRandomAffix())
		{
			Owner.A_Print("$BIO_MUTA_FAIL_NOCOMPATIBLEAFFIXES", 4.0);
			return false;
		}

		weap.OnChange();
		Owner.A_Print("$BIO_MUTA_ADD_USE");
		return true;
	}
}

class BIO_Muta_Random : BIO_Mutagen
{
	Default
	{
		Tag "$BIO_MUTA_RANDOM_TAG";
		Inventory.Icon 'MURAA0';
		Inventory.PickupMessage "$BIO_MUTA_RANDOM_PKUP";
		Inventory.UseSound "bio/muta/use/general";
		BIO_Mutagen.DropWeight DROPWT_RANDOM;
	}

	States
	{
	Spawn:
		MURA A 6;
		---- A 6 Bright Light("BIO_Muta_Random");
		Loop;
	}

	final override bool Use(bool pickup)
	{
		if (!super.Use(pickup)) return false;
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);

		if (weap.MaxAffixes < 1)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_MAX0");
			return false;
		}

		weap.RandomizeAffixes();
		weap.OnChange();
		Owner.A_Print("$BIO_MUTA_RANDOM_USE");
		return true;
	}
}

// For affixes which are initialized with random values, recompute these values.
class BIO_Muta_Reroll : BIO_Mutagen
{
	Default
	{
		Tag "$BIO_MUTA_REROLL_TAG";
		Inventory.Icon 'MURRA0';
		Inventory.PickupMessage "$BIO_MUTA_REROLL_PKUP";
		Inventory.UseSound "bio/muta/use/general";
		BIO_Mutagen.DropWeight DROPWT_REROLL;
		BIO_Mutagen.WorksOnUniques true;
	}

	States
	{
	Spawn:
		MURR A 6;
		---- A 6 Bright Light("BIO_Muta_Reroll");
		Loop;
	}

	final override bool Use(bool pickup)
	{
		if (!super.Use(pickup)) return false;
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);

		if (weap.NoAffixes())
		{
			Owner.A_Print("$BIO_MUTA_FAIL_NOAFFIXES", 4.0);
			return false;
		}

		bool anySupportReroll = false;

		for (uint i = 0; i < weap.ImplicitAffixes.Size(); i++)
			anySupportReroll |= weap.ImplicitAffixes[i].SupportsReroll(weap.AsConst());

		for (uint i = 0; i < weap.Affixes.Size(); i++)
			anySupportReroll |=  weap.Affixes[i].SupportsReroll(weap.AsConst());

		if (!anySupportReroll)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_NOREROLLSUPPORT", 4.0);
			return false;
		}

		weap.Reset();

		for (uint i = 0; i < weap.Affixes.Size(); i++)
		{
			weap.Affixes[i] = BIO_WeaponAffix(new(weap.Affixes[i].GetClass()));
			weap.Affixes[i].Init(weap.AsConst());
		}

		weap.OnChange();

		Owner.A_Print("$BIO_MUTA_REROLL_USE");
		return true;
	}
}

// Remove one affix at random from a weapon.
class BIO_Muta_Remove : BIO_Mutagen
{
	Default
	{
		Tag "$BIO_MUTA_REMOVE_TAG";
		Inventory.Icon 'MURMA0';
		Inventory.PickupMessage "$BIO_MUTA_REMOVE_PKUP";
		Inventory.UseSound "bio/muta/use/undo";
		BIO_Mutagen.DropWeight DROPWT_REMOVE;
	}

	States
	{
	Spawn:
		MURM A 6;
		---- A 6 Bright Light("BIO_Muta_Remove");
		Loop;
	}

	final override bool Use(bool pickup)
	{
		if (!super.Use(pickup)) return false;
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);

		if (weap.Affixes.Size() < 1)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_NOAFFIXES", 4.0);
			return false;
		}

		weap.Affixes.Delete(Random[BIO_Afx](0, weap.Affixes.Size() - 1));
		weap.OnChange();

		Owner.A_Print("$BIO_MUTA_REMOVE_USE");
		return true;
	}
}

class BIO_Muta_Upgrade : BIO_Mutagen
{
	Default
	{
		Tag "$BIO_MUTA_UPGRADE_TAG";
		Inventory.Icon 'MUUPA0';
		Inventory.PickupMessage "$BIO_MUTA_UPGRADE_PKUP";
		BIO_Mutagen.DropWeight DROPWT_UPGRADE;
		BIO_Mutagen.WorksOnUniques true;
	}

	States
	{
	Spawn:
		MUUP A 6;
		---- A 6 Bright Light("BIO_Muta_Upgrade");
		Loop;
	}

	private bool RandomUpgrade()
	{
		Array<BIO_WeaponUpgrade> options;

		BIO_GlobalData.Get().PossibleWeaponUpgrades(
			options, BIO_Weapon(Owner.Player.ReadyWeapon).GetClass());

		if (options.Size() < 1)
		{
			Owner.A_Print("$BIO_WUP_FAIL_NOOPTIONS");
			return false;
		}

		let oldWeap = BIO_Weapon(Owner.Player.ReadyWeapon);
		bool mut = oldWeap.Rarity == BIO_RARITY_MUTATED;

		// Don't try to give the user a weapon they already have;
		// don't try to give the user a weapon of lesser or equal grade
		for (uint i = options.Size() - 1; i >= 0; i--)
		{
			if (Owner.FindInventory(options[i].Output) ||
				GetDefaultByType(options[i].Output).Grade <= oldWeap.Grade)
				options.Delete(i);
		}

		let recipe = options[Random[BIO_Afx](0, options.Size() - 1)];
		Class<BIO_Weapon> output = recipe.Output;
		Owner.A_SelectWeapon('BIO_Fist');
		Owner.TakeInventory(oldWeap.GetClass(), 1);
		Owner.GiveInventory(output, 1);

		if (mut)
		{
			let newWeap = BIO_Weapon(Owner.FindInventory(output));
			newWeap.RandomizeAffixes();
			newWeap.OnChange();
		}

		Owner.A_SelectWeapon(output);
		Owner.A_StartSound("bio/item/weapupgrade/use", CHAN_AUTO);
		Owner.A_StartSound("bio/muta/use/general", CHAN_7);

		return true;
	}

	final override bool Use(bool pickup)
	{
		if (!super.Use(pickup)) return false;
		EventHandler.SendNetworkEvent(BIO_EventHandler.EVENT_WUPOVERLAY);
		return false;
	}
}

class BIO_Muta_Recycle : BIO_Mutagen
{
	Default
	{
		Tag "$BIO_MUTA_RECYCLE_TAG";
		Inventory.Icon 'MURCA0';
		Inventory.PickupMessage "$BIO_MUTA_RECYCLE_PKUP";
		Inventory.UseSound "bio/muta/use/undo";
		BIO_Mutagen.DropWeight DROPWT_RECYCLE;
		BIO_Mutagen.WorksOnUniques true;
	}

	States
	{
	Spawn:
		MURC A 6;
		---- A 6 Bright Light("BIO_Muta_Recycle");
		Loop;
	}

	final override bool Use(bool pickup)
	{
		if (!super.Use(pickup)) return false;
		
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);
		BIO_WeaponAffix afx = null;

		if (weap.Rarity == BIO_RARITY_UNIQUE)
		{
			if (weap.NoImplicitAffixes())
			{
				Owner.A_Print("$BIO_MUTA_FAIL_NOIMPLICITS");
				return false;
			}

			afx = weap.ImplicitAffixes[Random[BIO_Afx](0, weap.ImplicitAffixes.Size() - 1)];
		}
		else if (weap.Rarity == BIO_RARITY_MUTATED)
		{
			if (weap.NoExplicitAffixes())
			{
				Owner.A_Print("$BIO_MUTA_FAIL_NOEXPLICITS");
				return false;
			}

			afx = weap.Affixes[Random[BIO_Afx](0, weap.Affixes.Size() - 1)];
		}
		else
		{
			Owner.A_Print("$BIO_MUTA_FAIL_COMMON");
			return false;
		}

		Owner.TakeInventory(weap.GetClass(), 1);
		Owner.A_Print("$BIO_MUTA_RECYCLE_USE");

		for (Inventory i = Owner.Inv; i != null; i = i.Inv)
		{
			let genes = BIO_RecombinantGenes(i);

			if (genes != null && genes.AffixType == afx.GetClass())
			{
				genes.Amount = Min(genes.Amount + 1, genes.MaxAmount);
				return true;
			}
		}

		let genes = BIO_RecombinantGenes(
			Actor.Spawn('BIO_RecombinantGenes', Owner.Pos));

		if (genes == null)
		{
			Console.Printf(Biomorph.LOGPFX_ERR ..
				"Failed to spawn recombinant gene item.");
			return false;
		}

		genes.AffixType = afx.GetClass();
		genes.AttachToOwner(Owner);
		return true;
	}
}

class BIO_RecombinantGenes : Inventory
{
	Class<BIO_WeaponAffix> AffixType;

	Default
	{
		-COUNTITEM
		+DONTGIB
		+INVENTORY.INVBAR
		+NOBLOCKMONST
	
		Height 16;
		Radius 20;
		Tag "$BIO_RECOMBGENES_TAG";

		Inventory.Icon 'RECOA0';
		Inventory.InterHubAmount 99;
		Inventory.MaxAmount 99;
		Inventory.PickupMessage "$BIO_RECOMBGENES_PKUP";
		Inventory.UseSound "bio/muta/use/general";
	}

	States
	{
	Spawn:
		RECO A 6;
		---- A 6 Bright Light("BIO_RecombinantGenes");
		Loop;
	}

	final override void PostBeginPlay()
	{
		super.PostBeginPlay();

		if (AffixType == null)
		{
			Console.Printf(Biomorph.LOGPFX_ERR ..
				"Recombinant genes failed to acquire an affix type.");
			return;
		}

		string newTag = Default.GetTag();
		newTag.AppendFormat("\n\n\c[White]%s\c-", 
			BIO_WeaponAffix(new(AffixType)).GetTag());
		SetTag(newTag);
	}

	// Prevent pickups from being folded together
	// unless they have the same type of affix.
	final override bool HandlePickup(Inventory item)
	{
		let gene = BIO_RecombinantGenes(item);

		if (gene == null || gene.AffixType != AffixType)
			return false;

		Amount = Min(Amount + 1, MaxAmount);
		gene.bPickupGood = true;
		return true;
	}

	final override bool Use(bool pickup)
	{
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);

		if (weap == null)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_NULLWEAP", 4.0);
			return false;
		}

		if (weap.BIOFlags & BIO_WF_CORRUPTED)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_CORRUPTED");
			return false;
		}

		if (weap.Rarity == BIO_RARITY_UNIQUE)
		{
			Owner.A_Print("$BIO_MUTA_FAIL_UNIQUE", 4.0);
			return false;
		}

		if (weap.FullOnAffixes())
		{
			Owner.A_Print("$BIO_MUTA_FAIL_MAXAFFIXES");
			return false;
		}

		let affix = BIO_WeaponAffix(new(AffixType));

		if (weap.HasAffixOfType(affix.GetClass()))
		{
			Owner.A_Print("$BIO_RECOMBGENES_FAIL_OVERLAP", 5.0);
			return false;
		}

		if (!affix.Compatible(weap.AsConst()))
		{
			Owner.A_Print("$BIO_RECOMBGENES_FAIL_INCOMPAT", 5.0);
			return false;
		}

		uint e = weap.Affixes.Push(affix);
		weap.Affixes[e].Init(weap.AsConst());
		weap.OnChange();
		Owner.A_Print("$BIO_MUTA_ADD_USE");
		return true;
	}

	final override Inventory CreateTossable(int amt)
	{
		let ret = BIO_RecombinantGenes(super.CreateTossable(amt));
		ret.AffixType = AffixType;
		return ret;
	}

	readOnly<BIO_RecombinantGenes> AsConst() const { return self; }
}

class BIO_Muta_Corrupting : BIO_Mutagen
{
	Default
	{
		Tag "$BIO_MUTA_CORRUPT_TAG";
		Inventory.Icon 'MUCOA0';
		Inventory.PickupMessage "$BIO_MUTA_CORRUPT_PKUP";
		Inventory.UseSound "bio/muta/use/corrupt";
		BIO_Mutagen.DropWeight DROPWT_CORR;
		BIO_Mutagen.WorksOnUniques true;
	}

	States
	{
	Spawn:
		MUCO A 6;
		---- A 6 Bright Light("BIO_Muta_Corrupting");
		Loop;
	}

	final override bool Use(bool pickup)
	{
		if (!super.Use(pickup)) return false;
		let weap = BIO_Weapon(Owner.Player.ReadyWeapon);

		bool proceed = true, consumed = true;
		[proceed, consumed] = weap.OnCorrupt();

		if (!proceed) return consumed;

		Array<BIO_CorruptionFunctor> funcs;
		
		for (uint i = 0; i < AllClasses.Size(); i++)
		{
			let t = (Class<BIO_CorruptionFunctor>)(AllClasses[i]);
			if (t == null || t.IsAbstract()) continue;
			let func = BIO_CorruptionFunctor(new(t));
			if (!func.Compatible(weap.AsConst())) continue;
			funcs.Push(func);
		}

		funcs[Random[BIO_Afx](0, funcs.Size() - 1)].Invoke(weap);
		weap.BIOFlags |= BIO_WF_CORRUPTED;
		weap.OnChange();
		BIO_Utils.DRLMDangerLevel(1);
		return true;
	}
}

class BIO_CorruptionFunctor play abstract
{
	abstract void Invoke(BIO_Weapon weap) const;
	abstract bool Compatible(readOnly<BIO_Weapon> weap) const;
}

// The corruption flag gets set but nothing else happens. Congratulations!
class BIO_CorrFunc_Noop : BIO_CorruptionFunctor
{
	final override void Invoke(BIO_Weapon weap) const
	{
		weap.Owner.A_Print("$BIO_MUTA_CORRUPT_USE_NOOP");
	}

	final override bool Compatible(readOnly<BIO_Weapon> weap) const { return true; }
}

// Randomize affixes and then obfuscates them from the player.
class BIO_CorrFunc_RandomizeHide : BIO_CorruptionFunctor
{
	final override void Invoke(BIO_Weapon weap) const
	{
		weap.RandomizeAffixes(rerandomize: false);
		weap.BIOFlags |= BIO_WF_AFFIXESHIDDEN;
		// `OnChange()` not called because caller does so
		weap.Owner.A_Print("$BIO_MUTA_CORRUPT_USE_HIDDENRAND", 3.5);
	}

	final override bool Compatible(readOnly<BIO_Weapon> weap) const
	{
		return true;
	}
}

// Add either one or two implicit affixes.
class BIO_CorrFunc_Implicit : BIO_CorruptionFunctor
{
	Array<Class<BIO_WeaponAffix> > Eligibles;

	final override void Invoke(BIO_Weapon weap) const
	{
		if (Eligibles.Size() == 1)
		{
			uint r = Random[BIO_Afx](0, Eligibles.Size() - 1);
			let afx = BIO_WeaponAffix(new(Eligibles[r]));
			uint e = weap.ImplicitAffixes.Push(afx);
			weap.ImplicitAffixes[e].Init(weap.AsConst());
		}
		else
		{
			uint r = Random[BIO_Afx](0, Eligibles.Size() - 1);
			let afx1 = BIO_WeaponAffix(new(Eligibles[r]));
			uint e = weap.ImplicitAffixes.Push(afx1);
			weap.ImplicitAffixes[e].Init(weap.AsConst());
			weap.OnChange(rewriteReadout: false); // Readout gets rewritten by caller

			Eligibles.Delete(r);

			r = Random[BIO_Afx](0, Eligibles.Size() - 1);
			let afx2 = BIO_WeaponAffix(new(Eligibles[r]));
			e = weap.ImplicitAffixes.Push(afx2);
			weap.ImplicitAffixes[e].Init(weap.AsConst());
		}

		weap.Owner.A_Print("$BIO_MUTA_CORRUPT_USE_IMPLICIT", 3.5);
	}

	final override bool Compatible(readOnly<BIO_Weapon> weap) const
	{
		return BIO_GlobalData.Get().EligibleWeaponAffixes(Eligibles, weap, true);
	}
}
