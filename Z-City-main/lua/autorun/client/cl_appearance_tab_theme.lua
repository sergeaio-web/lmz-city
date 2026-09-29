if SERVER then return end

hg = hg or {}

local THEME = {
    background = Color(10, 7, 14, 255),
    backgroundSecondary = Color(18, 9, 24, 245),

    grid = Color(100, 45, 125, 95),
    accent = Color(255, 105, 210, 255),
    accentSoft = Color(190, 70, 165, 180),

    panel = Color(35, 17, 43, 240),
    panelHover = Color(65, 25, 75, 250),

    text = Color(255, 238, 253, 255),
    textSoft = Color(205, 165, 215, 220),

    input = Color(16, 8, 22, 250),
    border = Color(170, 80, 190, 220),

    scrollbar = Color(25, 10, 32, 240),
    scrollbarGrip = Color(130, 55, 150, 255),
    scrollbarGripHover = Color(230, 95, 200, 255)
}

local appearanceStyledPanels = setmetatable({}, {
    __mode = "k"
})

local appearanceStyledButtons = setmetatable({}, {
    __mode = "k"
})

local function DrawCrossPattern(w, h)
    local cellSize = ScreenScale(58)
    local speed = ScreenScale(15)
    local time = RealTime()

    local offsetX = (time * speed) % cellSize
    local offsetY = (time * speed * 0.65) % cellSize

    surface.SetDrawColor(
        THEME.grid.r,
        THEME.grid.g,
        THEME.grid.b,
        THEME.grid.a
    )

    for x = -cellSize, w + cellSize, cellSize do
        for y = -cellSize, h + cellSize, cellSize do
            local posX = math.floor(x + offsetX)
            local posY = math.floor(y + offsetY)
            local arm = ScreenScale(8)

            surface.DrawLine(
                posX - arm,
                posY,
                posX + arm,
                posY
            )

            surface.DrawLine(
                posX,
                posY - arm,
                posX,
                posY + arm
            )
        end
    end

    surface.SetDrawColor(
        THEME.accent.r,
        THEME.accent.g,
        THEME.accent.b,
        20
    )

    surface.DrawRect(0, 0, ScreenScale(2), h)
    surface.DrawRect(w - ScreenScale(2), 0, ScreenScale(2), h)
end

local function PaintAppearanceBackground(self, w, h)
    surface.SetDrawColor(
        THEME.background.r,
        THEME.background.g,
        THEME.background.b,
        THEME.background.a
    )

    surface.DrawRect(0, 0, w, h)

    DrawCrossPattern(w, h)

    surface.SetDrawColor(0, 0, 0, 45)
    surface.DrawRect(0, 0, w, h)
end

local function LerpColor(progress, first, second)
    return first:Lerp(second, math.Clamp(progress, 0, 1))
end

local function PaintAppearanceButton(self, w, h)
    local target = self:IsHovered() and 1 or 0

    self.AppearanceHover = Lerp(
        FrameTime() * 8,
        self.AppearanceHover or 0,
        target
    )

    local progress = self.AppearanceHover

    local background = LerpColor(
        progress,
        THEME.panel,
        THEME.panelHover
    )

    draw.RoundedBox(
        4,
        0,
        0,
        w,
        h,
        background
    )

    local border = LerpColor(
        progress,
        THEME.border,
        THEME.accent
    )

    surface.SetDrawColor(
        border.r,
        border.g,
        border.b,
        border.a
    )

    surface.DrawOutlinedRect(0, 0, w, h, 1)

    surface.SetDrawColor(
        THEME.accent.r,
        THEME.accent.g,
        THEME.accent.b,
        70 + progress * 130
    )

    surface.DrawRect(
        0,
        h - ScreenScale(1),
        w,
        ScreenScale(1)
    )

    if self.SetTextColor then
        self:SetTextColor(
            LerpColor(
                0.6 + progress * 0.4,
                THEME.textSoft,
                THEME.text
            )
        )
    end
end

local function PaintAppearanceTextEntry(self, w, h)
    local progress = self:IsHovered() and 1 or 0

    surface.SetDrawColor(
        THEME.input.r,
        THEME.input.g,
        THEME.input.b,
        THEME.input.a
    )

    surface.DrawRect(0, 0, w, h)

    local border = LerpColor(
        progress,
        THEME.border,
        THEME.accent
    )

    surface.SetDrawColor(
        border.r,
        border.g,
        border.b,
        border.a
    )

    surface.DrawOutlinedRect(0, 0, w, h, 1)

    self:DrawTextEntryText(
        THEME.text,
        THEME.accent,
        THEME.text
    )
end

local function StyleScrollBar(scroll)
    if not IsValid(scroll) then return end

    local bar = scroll:GetVBar()

    if not IsValid(bar) then return end

    bar:SetWide(ScreenScale(5))
    bar:SetHideButtons(true)

    bar.Paint = function(self, w, h)
        surface.SetDrawColor(
            THEME.scrollbar.r,
            THEME.scrollbar.g,
            THEME.scrollbar.b,
            THEME.scrollbar.a
        )

        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(
            THEME.border.r,
            THEME.border.g,
            THEME.border.b,
            120
        )

        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    if IsValid(bar.btnGrip) then
        bar.btnGrip.Paint = function(self, w, h)
            local gripColor = self:IsHovered()
                and THEME.scrollbarGripHover
                or THEME.scrollbarGrip

            draw.RoundedBox(
                4,
                1,
                1,
                w - 2,
                h - 2,
                gripColor
            )

            surface.SetDrawColor(
                THEME.accent.r,
                THEME.accent.g,
                THEME.accent.b,
                140
            )

            surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
        end
    end
end

local function StylePanel(panel)
    if not IsValid(panel) then return end
    if appearanceStyledPanels[panel] then return end

    appearanceStyledPanels[panel] = true

    local className = panel:GetClass()

    if className == "DScrollPanel" then
        StyleScrollBar(panel)
    end

    if className == "DTextEntry" then
        panel.Paint = function(self, w, h)
            PaintAppearanceTextEntry(self, w, h)
        end

        panel:SetTextColor(THEME.text)
    end

    if className == "DButton"
    or className == "DComboBox" then
        if not appearanceStyledButtons[panel] then
            appearanceStyledButtons[panel] = true

            panel.Paint = function(self, w, h)
                PaintAppearanceButton(self, w, h)
            end

            if panel.SetTextColor then
                panel:SetTextColor(THEME.text)
            end
        end
    end

    if className == "DPanel"
    and panel:GetParent()
    and panel:GetParent():GetClass() == "DModelPanel" then
        panel.Paint = function(self, w, h)
            PaintAppearanceButton(self, w, h)
        end
    end
end

local function StyleAppearanceChildren(parent)
    if not IsValid(parent) then return end

    StylePanel(parent)

    for _, child in ipairs(parent:GetChildren()) do
        StyleAppearanceChildren(child)
    end
end

local function StyleAppearanceMenu()
    if not IsValid(zpan) then return false end

    local appearanceMenu = zpan

    appearanceMenu.Paint = function(self, w, h)
        PaintAppearanceBackground(self, w, h)
    end

    StyleAppearanceChildren(appearanceMenu)

    return true
end

local function StartAppearanceStyling()
    local timerName = "HG_StyleAppearanceMenu"

    timer.Remove(timerName)

    timer.Create(timerName, 0.2, 50, function()
        if not IsValid(zpan) then return end

        StyleAppearanceMenu()
    end)
end

local function HookAppearanceCreator()
    if not hg.CreateApperanceMenu then
        return false
    end

    if hg.CreateApperanceMenu.__AppearanceThemeWrapped then
        return true
    end

    local oldCreateAppearanceMenu = hg.CreateApperanceMenu

    local function CreateStyledAppearanceMenu(...)
        local result = oldCreateAppearanceMenu(...)

        StartAppearanceStyling()

        return result
    end

    CreateStyledAppearanceMenu.__AppearanceThemeWrapped = true
    hg.CreateApperanceMenu = CreateStyledAppearanceMenu

    return true
end

timer.Create(
    "HG_WaitForAppearanceCreator",
    1,
    0,
    function()
        if HookAppearanceCreator() then
            timer.Remove("HG_WaitForAppearanceCreator")
        end
    end
)

hook.Add(
    "Think",
    "HG_RefreshAppearanceTabTheme",
    function()
        if not IsValid(zpan) then return end

        if zpan.AppearanceThemeNextUpdate
        and zpan.AppearanceThemeNextUpdate > RealTime() then
            return
        end

        zpan.AppearanceThemeNextUpdate = RealTime() + 0.5

        StyleAppearanceMenu()
    end
)