inherited Plot1DLineForm: TPlot1DLineForm
  Left = 207
  Top = 225
  Width = 736
  Height = 331
  Caption = 'Plot1DLineForm'
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  inherited Splitter1: TSplitter
    Height = 254
  end
  inherited Panel1: TPanel
    Height = 254
    inherited Splitter2: TSplitter
      Top = 210
    end
    inherited Panel2: TPanel
      Height = 210
      inherited Memo1: TMemo
        Height = 189
      end
    end
    inherited Panel3: TPanel
      Top = 213
    end
  end
  inherited Panel5: TPanel
    Width = 688
    Height = 254
    inherited Image1: TImage
      Width = 684
      Height = 250
    end
  end
  inherited StatusBar1: TStatusBar
    Top = 254
    Width = 720
  end
  inherited Panel6: TPanel
    Left = 693
    Height = 254
    object SpeedButton3: TSpeedButton [0]
      Left = 2
      Top = 86
      Width = 25
      Height = 25
      Hint = 'Fit Parabola'
      GroupIndex = 2
      Glyph.Data = {
        76010000424D7601000000000000760000002800000020000000100000000100
        0400000000000001000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
        555555F55555555555F5505555555555505557FFFFFFFFFFF7FF000000000000
        00057777777777777775505555555555505557F55555FFF55755505555599955
        555557F55557775F5555505555954595555557F55575FF7F55555054559CCC95
        555557F55577777FF55550555C94559C455557F55775FF775F555055C5599945
        C54557F57F5777557F555045C4555555C55557F57555555575F5505C55555555
        5C5557F7F555555557F5505C455555545C5557F7F555555557F5504C55555555
        5C4557F7555555555755505555555555555557FF555555555555000545555555
        5455777555555555555550555555555555555755555555555555}
      NumGlyphs = 2
      ParentShowHint = False
      ShowHint = True
    end
    object SpeedButton14: TSpeedButton [1]
      Left = 2
      Top = 112
      Width = 25
      Height = 25
      Hint = 'Fit Exponential'
      GroupIndex = 2
      Glyph.Data = {
        76010000424D7601000000000000760000002800000020000000100000000100
        0400000000000001000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
        555555F55555555555F5505555555555505557FFFFFFFFFFF7F5000000000000
        0005777777777777777F505555554555505557F55555555FF7555055555555CC
        CC5557F55555FF7777555055545CCC54545557F5555777555555505455C55545
        555557F555755555555550555C454555555557F55755555555555055C5555555
        555557F57F55555555555045C4555555555557F5755555F55FFF505C55555155
        111557F7F55557F57775505C45555155515557F7F55557F557F5504C55555155
        515557F7555557F557F5505555555155115557FF555557FF77F5000545551115
        5155777555557775575550555555555555555755555555555555}
      NumGlyphs = 2
      ParentShowHint = False
      ShowHint = True
    end
    inherited CloneButton: TSpeedButton
      Hint = 'Opens a copy of the plot in a new window'
      ParentShowHint = False
      ShowHint = True
    end
    object Panel7: TPanel
      Left = 0
      Top = 142
      Width = 29
      Height = 42
      BevelOuter = bvNone
      TabOrder = 0
      object SpeedButton4: TSpeedButton
        Left = 2
        Top = 2
        Width = 12
        Height = 12
        Hint = 'Big Dots'
        GroupIndex = 3
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0055555555FFF5
          00005444555777FF000044444577777F000044444577777F0000444445777775
          00005444555777550000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton6: TSpeedButton
        Left = 15
        Top = 2
        Width = 12
        Height = 12
        Hint = 'Medium Dots'
        GroupIndex = 3
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555F55
          0000554555557FF500005444555777FF00004444457777750000544455577755
          00005545555575550000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton8: TSpeedButton
        Left = 2
        Top = 15
        Width = 12
        Height = 12
        Hint = 'Small Dots'
        GroupIndex = 3
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
          000055555555FFF500005444555777F500005444555777F50000544455577755
          00005555555555550000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton5: TSpeedButton
        Left = 15
        Top = 15
        Width = 12
        Height = 12
        Hint = 'Tiny Dots'
        GroupIndex = 3
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
          0000555555555F550000554555557FF500005444555777550000554555557555
          00005555555555550000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton7: TSpeedButton
        Left = 2
        Top = 28
        Width = 12
        Height = 12
        Hint = 'No Dots'
        GroupIndex = 3
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0055555555F5F5
          000053535557575500005555555F555F0000355535755575000055555555F5F5
          00005353555757550000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton9: TSpeedButton
        Left = 15
        Top = 28
        Width = 12
        Height = 12
        Hint = 'Use Default Dot Size'
        GroupIndex = 3
        Down = True
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888F88
          0000881888887FF800008111888777FF00001111187777780000881888887F88
          00008818888878880000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
    end
    object Panel8: TPanel
      Left = 0
      Top = 184
      Width = 29
      Height = 29
      BevelOuter = bvNone
      TabOrder = 1
      object SpeedButton10: TSpeedButton
        Left = 2
        Top = 2
        Width = 12
        Height = 12
        Hint = 'Thick Lines'
        GroupIndex = 4
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
          00008888888FFFFF000044444877777F00004444487777780000888888888888
          00008888888888880000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton11: TSpeedButton
        Left = 15
        Top = 2
        Width = 12
        Height = 12
        Hint = 'Thin Lines'
        GroupIndex = 4
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888888
          000088888888888800008888888FFFFF00004444487777780000888888888888
          00008888888888880000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton13: TSpeedButton
        Left = 2
        Top = 15
        Width = 12
        Height = 12
        Hint = 'No Lines'
        GroupIndex = 4
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF0055555555F5F5
          000053535557575500005555555F555F0000355535755575000055555555F5F5
          00005353555757550000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton12: TSpeedButton
        Left = 15
        Top = 15
        Width = 12
        Height = 12
        Hint = 'Use Default Line Width'
        GroupIndex = 4
        Down = True
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888F88
          0000881888887FF800008111888777FF00001111187777780000881888887F88
          00008818888878880000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
    end
    object Panel9: TPanel
      Left = 0
      Top = 212
      Width = 29
      Height = 29
      BevelOuter = bvNone
      TabOrder = 2
      object SpeedButton15: TSpeedButton
        Left = 2
        Top = 2
        Width = 12
        Height = 12
        Hint = 'Dark Grid'
        GroupIndex = 4
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF005555555FFFFF
          000000000577777500000550557F555500000550557F555500000000057F5555
          00000550557555550000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton16: TSpeedButton
        Left = 15
        Top = 2
        Width = 12
        Height = 12
        Hint = 'Light Grid'
        GroupIndex = 4
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF005555555FFFFF
          000000000577777500000557557F555500000557557F555500000777757F5555
          00000557557555550000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton17: TSpeedButton
        Left = 2
        Top = 15
        Width = 12
        Height = 12
        Hint = 'No Grid'
        GroupIndex = 4
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF008888888FFFFF
          000000000877777800000888887F888800000888887F888800000888887F8888
          00000888887888880000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
      object SpeedButton18: TSpeedButton
        Left = 15
        Top = 15
        Width = 12
        Height = 12
        Hint = 'Use Default Grid'
        GroupIndex = 4
        Down = True
        Glyph.Data = {
          A6000000424DA60000000000000076000000280000000C000000060000000100
          0400000000003000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00888888888F88
          0000881888887FF800008111888777FF00001111187777780000881888887F88
          00008818888878880000}
        NumGlyphs = 2
        ParentShowHint = False
        ShowHint = True
        OnClick = FormResize
      end
    end
  end
  inherited MainMenu1: TMainMenu
    inherited MenuView: TMenuItem
      object MenuVPointsSize: TMenuItem
        Caption = '&Dot Size'
        object MenuVDSLarge: TMenuItem
          Caption = '&Large'
          RadioItem = True
          OnClick = MenuVDSLargeClick
        end
        object MenuVDSMedium: TMenuItem
          Caption = '&Medium'
          RadioItem = True
          OnClick = MenuVDSMediumClick
        end
        object MenuVDSSmall: TMenuItem
          Caption = '&Small'
          RadioItem = True
          OnClick = MenuVDSSmallClick
        end
        object MenuVDSTiny: TMenuItem
          Caption = '&Tiny'
          RadioItem = True
          OnClick = MenuVDSTinyClick
        end
        object MenuVDSNone: TMenuItem
          Caption = '&None'
          RadioItem = True
          OnClick = MenuVDSNoneClick
        end
        object MenuVDSDefault: TMenuItem
          Caption = '&Default'
          Checked = True
          RadioItem = True
          ShortCut = 24644
          OnClick = MenuVDSDefaultClick
        end
        object N4: TMenuItem
          Caption = '-'
        end
        object MenuVDSToggle: TMenuItem
          Caption = 'To&ggle'
          ShortCut = 16452
          OnClick = MenuVDSToggleClick
        end
      end
      object MenuVLineSize: TMenuItem
        Caption = '&Line Size'
        object MenuVLSThick: TMenuItem
          Caption = '&Thick'
          RadioItem = True
          OnClick = MenuVLSThickClick
        end
        object MenuVLSThin: TMenuItem
          Caption = 'Thi&n'
          RadioItem = True
          OnClick = MenuVLSThinClick
        end
        object MenuVLSNone: TMenuItem
          Caption = '&None'
          RadioItem = True
          OnClick = MenuVLSNoneClick
        end
        object MenuVLSDefault: TMenuItem
          Caption = '&Default'
          Checked = True
          RadioItem = True
          ShortCut = 24652
          OnClick = MenuVLSDefaultClick
        end
        object N3: TMenuItem
          Caption = '-'
        end
        object MenuVLSToggle: TMenuItem
          Caption = 'To&ggle'
          ShortCut = 16460
          OnClick = MenuVLSToggleClick
        end
      end
      object MenuVGrid: TMenuItem
        Caption = '&Grid'
        object MenuVGDark: TMenuItem
          Caption = 'Dar&k'
          RadioItem = True
          OnClick = MenuVGDarkClick
        end
        object MenuVGLight: TMenuItem
          Caption = '&Light'
          RadioItem = True
          OnClick = MenuVGLightClick
        end
        object MenuVGNone: TMenuItem
          Caption = '&None'
          RadioItem = True
          OnClick = MenuVGNoneClick
        end
        object MenuVGDefault: TMenuItem
          Caption = '&Default'
          Checked = True
          RadioItem = True
          ShortCut = 24647
          OnClick = MenuVGDefaultClick
        end
        object N6: TMenuItem
          Caption = '-'
        end
        object MenuVGToggle: TMenuItem
          Caption = 'To&ggle'
          ShortCut = 16455
          OnClick = MenuVGToggleClick
        end
      end
    end
  end
end
