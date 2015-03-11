object ServerSelectForm: TServerSelectForm
  Left = 886
  Top = 141
  Width = 378
  Height = 173
  BorderStyle = bsSizeToolWin
  Caption = 'Select Data Server...'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    362
    135)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 353
    Height = 101
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      'Memo1')
    ReadOnly = True
    TabOrder = 0
  end
  object ComboBox1: TComboBox
    Left = 8
    Top = 116
    Width = 289
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 1
  end
  object Button1: TButton
    Left = 304
    Top = 116
    Width = 57
    Height = 21
    Anchors = [akRight, akBottom]
    Caption = 'Select'
    Default = True
    ModalResult = 1
    TabOrder = 2
    OnClick = Button1Click
  end
end
