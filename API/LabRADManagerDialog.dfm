object ManagerDialogForm: TManagerDialogForm
  Left = 279
  Top = 426
  BorderStyle = bsToolWindow
  Caption = 'Connection Information'
  ClientHeight = 145
  ClientWidth = 268
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
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 25
    Height = 13
    Caption = 'Host:'
  end
  object Label2: TLabel
    Left = 212
    Top = 8
    Width = 22
    Height = 13
    Caption = 'Port:'
  end
  object Label3: TLabel
    Left = 204
    Top = 27
    Width = 3
    Height = 13
    Caption = ':'
  end
  object Label5: TLabel
    Left = 24
    Top = 56
    Width = 217
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'These settings can also be given in the'
  end
  object Label6: TLabel
    Left = 24
    Top = 72
    Width = 217
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = '"LabRADHost" and "LabRADPort"'
  end
  object Label7: TLabel
    Left = 24
    Top = 88
    Width = 217
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'environment variables'
  end
  object HostEdit: TEdit
    Left = 8
    Top = 24
    Width = 189
    Height = 21
    TabOrder = 0
    Text = 'localhost'
    OnKeyPress = HostEditKeyPress
  end
  object PortEdit: TEdit
    Left = 212
    Top = 24
    Width = 45
    Height = 21
    TabOrder = 1
    Text = '12345'
    OnKeyPress = PortEditKeyPress
  end
  object BitBtn1: TBitBtn
    Left = 100
    Top = 112
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      04000000000000010000220B0000220B00001000000010000000000000000000
      800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00555555555555
      555555555555555555555555555555555555555555FF5555555555555A055555
      55555555577FF55555555555AAA05555555555557777F55555555555AAA05555
      555555557777FF555555555AAAAA05555555555777777F55555555AAAAAA0555
      5555557777777FF5555557AA05AAA05555555777757777F555557A05555AA055
      55557775555777FF55555555555AAA05555555555557777F555555555555AA05
      555555555555777FF555555555555AA05555555555555777FF5555555555557A
      05555555555555777FF5555555555557A05555555555555777FF555555555555
      5AA0555555555555577755555555555555555555555555555555}
    NumGlyphs = 2
  end
  object BitBtn2: TBitBtn
    Left = 184
    Top = 112
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
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
