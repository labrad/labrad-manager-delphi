object KeyEditForm: TKeyEditForm
  Left = 279
  Top = 834
  Width = 545
  Height = 292
  BorderStyle = bsSizeToolWin
  Caption = 'Edit Key Value'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object TopPanel: TPanel
    Left = 0
    Top = 0
    Width = 537
    Height = 23
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object PathPanel: TPanel
      Left = 0
      Top = 0
      Width = 537
      Height = 21
      Align = alTop
      Alignment = taLeftJustify
      BevelOuter = bvNone
      BorderStyle = bsSingle
      Caption = ' >> Root >> Something'
      TabOrder = 0
    end
  end
  object BottomPanel: TPanel
    Left = 0
    Top = 234
    Width = 537
    Height = 31
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      537
      31)
    object UpdateButton: TBitBtn
      Left = 377
      Top = 4
      Width = 77
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Update'
      Default = True
      Enabled = False
      ModalResult = 1
      TabOrder = 0
      Glyph.Data = {
        76010000424D7601000000000000760000002800000020000000100000000100
        04000000000000010000120B0000120B00001000000000000000000000000000
        800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
        555555FFFFFFFFFF5F5557777777777505555777777777757F55555555555555
        055555555555FF5575F555555550055030555555555775F7F7F55555550FB000
        005555555575577777F5555550FB0BF0F05555555755755757F555550FBFBF0F
        B05555557F55557557F555550BFBF0FB005555557F55575577F555500FBFBFB0
        305555577F555557F7F5550E0BFBFB003055557575F55577F7F550EEE0BFB0B0
        305557FF575F5757F7F5000EEE0BFBF03055777FF575FFF7F7F50000EEE00000
        30557777FF577777F7F500000E05555BB05577777F75555777F5500000555550
        3055577777555557F7F555000555555999555577755555577755}
      NumGlyphs = 2
    end
    object CancelButton: TBitBtn
      Left = 458
      Top = 4
      Width = 77
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
      Glyph.Data = {
        76010000424D7601000000000000760000002800000020000000100000000100
        04000000000000010000130B0000130B00001000000000000000000000000000
        800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
        3333333333FFFFF3333333333999993333333333F77777FFF333333999999999
        3333333777333777FF3333993333339993333377FF3333377FF3399993333339
        993337777FF3333377F3393999333333993337F777FF333337FF993399933333
        399377F3777FF333377F993339993333399377F33777FF33377F993333999333
        399377F333777FF3377F993333399933399377F3333777FF377F993333339993
        399377FF3333777FF7733993333339993933373FF3333777F7F3399933333399
        99333773FF3333777733339993333339933333773FFFFFF77333333999999999
        3333333777333777333333333999993333333333377777333333}
      NumGlyphs = 2
    end
  end
  object ContentPanel: TPanel
    Left = 0
    Top = 23
    Width = 537
    Height = 211
    Align = alClient
    BevelOuter = bvNone
    BorderStyle = bsSingle
    TabOrder = 2
    object PContentEditorLegend: TPanel
      Left = 0
      Top = 0
      Width = 21
      Height = 207
      Align = alLeft
      Constraints.MinHeight = 150
      TabOrder = 0
      object Label3: TLabel
        Left = 4
        Top = 20
        Width = 13
        Height = 13
        Hint = 'Signed number (integer): +15, -29, +0, -0, ...'
        Alignment = taCenter
        AutoSize = False
        Caption = 'i'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label4: TLabel
        Left = 4
        Top = 36
        Width = 13
        Height = 13
        Hint = 'Unsigned number (word): 0, 37, $DEAD, $beef, $12AbC3f...'
        Alignment = taCenter
        AutoSize = False
        Caption = 'w'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clPurple
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label5: TLabel
        Left = 4
        Top = 68
        Width = 13
        Height = 13
        Hint = 
          'Real number (value), optional units: 15.0, 2e7, 0.0, 3.0 m/s^2, ' +
          '...'
        Alignment = taCenter
        AutoSize = False
        Caption = 'v'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label6: TLabel
        Left = 4
        Top = 84
        Width = 13
        Height = 13
        Hint = 
          'Complex number (complex), optional units: 12 + 3i, j, 1e6j, 1.2e' +
          '6i s, ...'
        Alignment = taCenter
        AutoSize = False
        Caption = 'c'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clTeal
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label7: TLabel
        Left = 4
        Top = 52
        Width = 13
        Height = 13
        Hint = 'Text (string): '#39#39', '#39'Say: "Hello"!'#39', "OK!", ...'
        Alignment = taCenter
        AutoSize = False
        Caption = 's'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label8: TLabel
        Left = 4
        Top = 100
        Width = 13
        Height = 13
        Hint = 
          'Time and/or date (timestamp): 2pm, 10:49p, 0:12:24.883, 12/19/20' +
          '07 3:15pm, 1/26/103 BC, ...'
        Alignment = taCenter
        AutoSize = False
        Caption = 't'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clOlive
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label9: TLabel
        Left = 4
        Top = 116
        Width = 13
        Height = 13
        Hint = 
          'Collection of heterogeneous data (cluster): ('#39'Tom'#39', 28), (2:45pm' +
          ', 0.3 V), ...'
        Alignment = taCenter
        AutoSize = False
        Caption = '( )'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 8404992
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label10: TLabel
        Left = 4
        Top = 132
        Width = 13
        Height = 13
        Hint = 
          'List or table of homogeneous data (array): [1.0 V, 1.1 V, 1.2 V]' +
          ', ['#39'You'#39', '#39'Me'#39'], [[[111,112,113],[121,122,123]],[[211,212,213],[' +
          '221,222,223]]], ...'
        Alignment = taCenter
        AutoSize = False
        Caption = '[ ]'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 16512
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object Label61: TLabel
        Left = 4
        Top = 4
        Width = 13
        Height = 13
        Hint = 'Flag (Boolean): F, T, tRuE, False, ...'
        Alignment = taCenter
        AutoSize = False
        Caption = 'b'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGreen
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
    end
    object Panel1: TPanel
      Left = 21
      Top = 0
      Width = 512
      Height = 207
      Align = alClient
      BevelOuter = bvNone
      Color = clWindow
      TabOrder = 1
      object TypeTagPanel: TPanel
        Left = 0
        Top = 185
        Width = 512
        Height = 22
        Align = alBottom
        Alignment = taLeftJustify
        Caption = ' Type Tag: '
        Constraints.MinWidth = 278
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object ContentEdit: TRichEdit
        Left = 0
        Top = 0
        Width = 512
        Height = 185
        Align = alClient
        BorderStyle = bsNone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = [fsBold]
        ParentFont = False
        ScrollBars = ssVertical
        TabOrder = 1
        OnChange = ContentEditChange
        OnKeyPress = ContentEditKeyPress
      end
    end
  end
  object ColorTimer: TTimer
    Enabled = False
    Interval = 333
    OnTimer = ColorTimerTimer
    Left = 28
    Top = 28
  end
end
