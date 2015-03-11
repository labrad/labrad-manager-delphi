object UserForm: TUserForm
  Left = 273
  Top = 430
  BorderStyle = bsToolWindow
  Caption = 'User'
  ClientHeight = 93
  ClientWidth = 257
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 4
    Top = 4
    Width = 31
    Height = 13
    Caption = 'Name:'
  end
  object Label2: TLabel
    Left = 0
    Top = 48
    Width = 257
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'This name will identify you when submitting comments'
  end
  object Edit1: TEdit
    Left = 8
    Top = 20
    Width = 241
    Height = 21
    TabOrder = 0
  end
  object Button1: TButton
    Left = 216
    Top = 68
    Width = 39
    Height = 21
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
end
