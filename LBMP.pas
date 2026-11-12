unit LBMP;

interface

Function LoadBmpFile(FFile:String; Var Width,Height:Integer):Pointer;
Procedure BindNewTexture(Texture:Pointer; TextureID, W, H:Integer);

implementation

Uses Windows,Graphics,Opengl15;

Function LoadBmpFile(FFile:String; Var Width,Height:Integer):Pointer;
procedure SwapRGB(data : Pointer; Size : Integer);
asm
  mov ebx, eax
  mov ecx, size

@@loop :
  mov al,[ebx+0]
  mov ah,[ebx+2]
  mov [ebx+2],al
  mov [ebx+0],ah
  add ebx,3
  dec ecx
  jnz @@loop
end;
var
  FileHeader: TBITMAPFILEHEADER;
  InfoHeader: TBITMAPINFOHEADER;
  Palette: array of RGBQUAD;
  BitmapFile: THandle;
  BitmapLength: LongWord;
  PaletteLength: LongWord;
  ReadBytes: LongWord;
begin
  BitmapFile := CreateFile(PChar(FFile), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  if (BitmapFile = INVALID_HANDLE_VALUE) then begin
    MessageBox(0, PChar('Error opening "' + FFile), PChar('BMP Unit'), MB_OK);
    Exit;
  end;

  // Get header information
  ReadFile(BitmapFile, FileHeader, SizeOf(FileHeader), ReadBytes, nil);
  ReadFile(BitmapFile, InfoHeader, SizeOf(InfoHeader), ReadBytes, nil);

  // Get palette
  PaletteLength := InfoHeader.biClrUsed;
  SetLength(Palette, PaletteLength);
  ReadFile(BitmapFile, Palette, PaletteLength, ReadBytes, nil);
  if (ReadBytes <> PaletteLength) then begin
    MessageBox(0, PChar('Error reading palette'), PChar('BMP Unit'), MB_OK);
    Exit;
  end;

  Width := InfoHeader.biWidth;
  Height := InfoHeader.biHeight;
  BitmapLength := InfoHeader.biSizeImage;
  if BitmapLength = 0 then
    BitmapLength := Width * Height * InfoHeader.biBitCount Div 8;

  // Get the actual pixel data
  GetMem(Result, BitmapLength);
  ReadFile(BitmapFile, Result^, BitmapLength, ReadBytes, nil);
  if (ReadBytes <> BitmapLength) then begin
    MessageBox(0, PChar('Error reading bitmap data'), PChar('BMP Unit'), MB_OK);
    Exit;
  end;
  CloseHandle(BitmapFile);

  // Bitmaps are stored BGR and not RGB, so swap the R and B bytes.
  SwapRGB(Result, Width*Height);
end;

Procedure BindNewTexture(Texture:Pointer; TextureID, W, H:Integer);
Begin
 glBindTexture(GL_TEXTURE_2D, TextureID);

 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);//>>-------------------------------------------->-
 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);//>>--------------------------------------------->-
                                                                                                         // |
 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, W, H, 0, GL_RGB, GL_UNSIGNED_BYTE, Texture);                     // |
// gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGB, 128, 128, GL_RGB, GL_UNSIGNED_BYTE, Texture);                  // |
 //gluBuild2DMipmapLevels(GL_TEXTURE_2D, GL_RGB, 128, 128, GL_RGB, GL_UNSIGNED_BYTE, 1, 0, 2, Texture);<--<-
End;

end.
