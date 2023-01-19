// Common code shared between the TooltipListMenu and TooltipOptionMenu.

class BIO_Tooltip : Object ui {
  double x, y, w, xpad, ypad, scale; // Geometry
  uint first, last; // First and last menuitems this applies to
  Font font;
  Color colour;
  TextureID texture;
  string text;

  void CopyFrom(BIO_Tooltip settings) {
    self.x = settings.x;
    self.y = settings.y;
    self.w = settings.w;
    self.xpad = settings.xpad;
    self.ypad = settings.ypad;
    self.scale = settings.scale;
    self.font = settings.font;
    self.colour = settings.colour;
    self.texture = settings.texture;
  }

  int GetX(uint screen_width, uint width) {
    return (screen_width - width) * self.x;
  }

  int GetY(uint screen_width, uint height) {
    return (screen_width - height) * self.y;
  }

  void Draw() {
    // In order to draw the text readably at high resolutions, we calculate
    // everything using a virtual screen size and then tell DrawTexture and
    // DrawText to scale appropriately when blitting the background and tooltip
    // text to the real screen.
    uint virtual_height = screen.GetHeight() / CleanYFac_1 / scale;
    let aspect = screen.GetAspectRatio();
    let virtual_width = virtual_height * aspect;
    // Font metrics: em width and line height.
    let em = self.font.GetCharWidth(0x6D);
    let lh = self.font.GetHeight();
    // Nominal width is the maximum width of the tooltip based on configuration
    // in the MENUDEF.
    let nominal_width = virtual_width * self.w;
    let lines = self.font.BreakLines(self.text, nominal_width);

    // Calculate the real width of the tooltip. This may be less than the
    // nominal width if it's a short one-liner. This is still in virtual screen
    // coordinates, not real screen!
    uint actual_width = 0;
    for (uint i = 0; i < lines.count(); ++i) {
      actual_width = max(actual_width, self.font.StringWidth(lines.StringAt(i)));
    }
    actual_width += self.xpad * 2.0 * em;

    // Calculate the real height based on the number of lines we wrapped it into
    // and the vertical margins.
    uint actual_height = self.font.GetHeight() * (self.ypad * 2.0 + lines.count());

    // Get the coordinates of the top left corner of the tooltip's bounding box,
    // including padding, in virtual screen coordinates.
    uint x = GetX(virtual_width, actual_width);
    uint y = GetY(virtual_height, actual_height);

    // Draw the background texture, if defined. DTA_Virtual* commands it to scale
    // the virtual screen size to match the real screen; DTA_KeepRatio tells it
    // to assume the ratio of the virtual screen matches the real screen. (The
    // documentation on the wiki is wrong here; leaving it false forces a 4:3
    // aspect ratio.)
    Screen.DrawTexture(texture, true, x, y,
        DTA_VirtualWidthF, virtual_width, DTA_VirtualHeight, virtual_height,
        DTA_KeepRatio, true,
        DTA_LeftOffset, 0, DTA_TopOffset, 0,
        DTA_DestWidth, actual_width, DTA_DestHeight, actual_height);

    for (uint i = 0; i < lines.count(); ++i) {
      screen.DrawText(
        self.font, self.colour,
        x + self.xpad*em,
        y + i*lh + self.ypad*lh,
        lines.StringAt(i),
        DTA_VirtualWidthF, virtual_width, DTA_VirtualHeight, virtual_height,
        DTA_KeepRatio, true);
    }
  }
}

// Mixin classes used for the menu and menu items.
mixin class BIO_TooltipMenu {
  array<BIO_Tooltip> tooltips;
  BIO_Tooltip tooltip_settings;

  // Default settings:
  // - top left corner
  // - 30% of the screen width
  // - 1em horizontal margin and 0.5lh vertical margin
  // - white text using newsmallfont
  BIO_Tooltip GetDefaults() {
    let tt = BIO_Tooltip(new("BIO_Tooltip"));
    tt.x = tt.y = 0.0;
    tt.w = 0.3;
    tt.xpad = 1.0;
    tt.ypad = 0.5;
    tt.scale = 1.0;
    tt.font = newsmallfont;
    tt.colour = Font.CR_WHITE;
    return tt;
  }

  BIO_Tooltip AppendableTooltip(uint first, uint last) {
    if (tooltips.size() <= 0) return null;
    let tt = tooltips[tooltips.size()-1];
    if (tt.first == first) return tt;
    return null;
  }

  void AddTooltip(uint first, uint last, string tooltip) {
    if (first < 0) ThrowAbortException("Tooltip must have at least one menu item preceding it!");
    let localtooltip = Stringtable.localize(tooltip);
    let tt = AppendableTooltip(first, last);
    if (tt) {
      // Existing tooltip that we're just appending to.
      tt.text = tt.text .. "\n" .. localtooltip;
      return;
    }
    // No existing tooltip for these menu entries, create a new one.
    tt = new("BIO_Tooltip");
    tt.CopyFrom(tooltip_settings);
    tt.first = first;
    tt.last = last;
    tt.text = localtooltip;
    tooltips.push(tt);
  }

  BIO_Tooltip FindTooltipFor(int item) {
    // console.printf("FindTooltipFor(%d)", item);
    if (item < 0 || item >= mDesc.mItems.size()) return null;
    if (!mDesc.mItems[item].Selectable()) return null;
    for (uint i = 0; i < tooltips.size(); ++i) {
      if (tooltips[i].first <= item && item <= tooltips[i].last) {
        // console.printf("Found %d <= %d <= %d",
        //   tooltips[i].first, i, tooltips[i].last);
        return tooltips[i];
      }
    }
    return null;
  }

  override void Drawer() {
    super.Drawer();
    let tt = FindTooltipFor(mDesc.mSelectedItem);
    if (tt) tt.Draw();
  }

  // Dynamic tooltip API.
  void PushTooltip(String tooltip, uint n=1) {
    if (!tooltip) return;
    if (n<1) ThrowAbortException("Tooltip must apply to at least one menu item!");
    AddTooltip(mDesc.mItems.size()-n, mDesc.mItems.size()-1, tooltip);
  }

  // ZScript doesn't have reify, so we just duplicate the CopyTo logic below here.
  void TooltipAppearance(string myfont="", string colour="", string texture="") {
    if (myfont != "") tooltip_settings.font = Font.GetFont(myfont);
    if (colour != "") tooltip_settings.colour = Font.FindFontColor(colour);
    if (texture != "") tooltip_settings.texture = TexMan.CheckForTexture(texture, TexMan.TYPE_ANY);
  }

  void TooltipGeometry(
      double x=-1.0, double y=-1.0, double w=-1.0,
      double xpad=-1.0, double ypad=-1.0, double scale=-1.0) {
    if (x >= 0) tooltip_settings.x = x;
    if (y >= 0) tooltip_settings.y = y;
    if (w >= 0) tooltip_settings.w = w;
    if (xpad >= 0) tooltip_settings.xpad = xpad;
    if (ypad >= 0) tooltip_settings.ypad = ypad;
    if (scale > 0) tooltip_settings.scale = scale;
  }
}

mixin class BIO_TooltipHolder {
  array<BIO_Tooltip> tooltips;

  Object Init(array<BIO_Tooltip> tts) {
    self.tooltips.copy(tts);
    return self;
  }

  override bool Selectable() { return false; }
}

mixin class BIO_TooltipItem {
  string tooltip;

  Object Init(string tooltip) {
    self.tooltip = tooltip.filter();
    return self;
  }
}

mixin class BIO_TooltipGeometry {
  double x, y, w, xpad, ypad, scale;

  Object Init(
      double x=-1.0, double y=-1.0, double w=-1.0,
      double xpad=-1.0, double ypad=-1.0,
      double scale=-1.0) {
    self.x = x; self.y = y; self.w = w;
    self.xpad = xpad; self.ypad = ypad;
    self.scale = scale;
    return self;
  }

  void CopyTo(BIO_Tooltip settings) {
    if (self.x >= 0) settings.x = self.x;
    if (self.y >= 0) settings.y = self.y;
    if (self.w >= 0) settings.w = self.w;
    if (self.xpad >= 0) settings.xpad = self.xpad;
    if (self.ypad >= 0) settings.ypad = self.ypad;
    if (self.scale > 0) settings.scale = self.scale;
  }
}

mixin class BIO_TooltipAppearance {
  Font myfont;
  Color colour;
  TextureID texture;

  Object Init(string myfont="", string colour="", string texture="") {
    if (myfont != "") self.myfont = Font.GetFont(myfont);
    if (colour != "") self.colour = Font.FindFontColor(colour);
    if (texture != "") self.texture = TexMan.CheckForTexture(texture, TexMan.TYPE_ANY);
    return self;
  }

  void CopyTo(BIO_Tooltip settings) {
    if (self.myfont) settings.font = self.myfont;
    if (self.colour) settings.colour = self.colour;
    if (self.texture) settings.texture = self.texture;
  }
}
