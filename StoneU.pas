{$A+,B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$MINSTACKSIZE $00004000}
{$MAXSTACKSIZE $00100000}
{$IMAGEBASE $00400000}
{$APPTYPE GUI}
unit StoneU;

interface

uses
  Windows,
  SysUtils,
  Forms,
  Classes,
  ExtCtrls,
  Buttons,
  OpenGL15, 
  Sounds,
  Models,
  Dialogs,
  Controls,
  LBMP;

Type PSharic=^Tsharic;
     Tsharic= Record
      SX,SY{,N}:Integer;
      Selected:Boolean;
      Material:GLuint;
      Next:PSharic;
     End;
type
  TStone = class(TForm)
    Panel1: TPanel;
    Resize: TSpeedButton;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    Moving: TTimer;
    SpeedButton10: TSpeedButton;
    SpeedButton11: TSpeedButton;
    OpenDialog1: TOpenDialog;
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormPaint(Sender: TObject);
    Procedure DrawPlant(MaxX,MaxY:Integer);
    Procedure DrawQuadSph(Rad,Segsx,Segsy:Glfloat);
    Procedure NewSH(X,Y:Integer);
    Procedure DellAll;
    Procedure PaintAll;
    procedure FormClick(Sender: TObject);
    Procedure DrawCirc(Rad:Glfloat; Segs:Integer);
    Procedure FindSelected;
    Procedure DrawIn(Rad:Glfloat; X,Y:Integer; Sel:Boolean);
    Procedure MoveTo(X,Y,EX,Ey:Integer);
    Procedure FindWay(X,Y,EX,Ey,N:Integer);
    Function KillSome:Boolean;
    Function GetColor(X,Y:Integer):Integer;
    Procedure Kill(X,Y:Integer);
    procedure newG;
    procedure NewGaClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    Procedure Outtext(TXT:Pchar);
    Procedure CreateTXT;
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure SpeedButton8Click(Sender: TObject);
    procedure SpeedButton9Click(Sender: TObject);
    function  Selectway(X,Y:Integer):String;
    procedure MovingTimer(Sender: TObject);
    procedure AfterMoving;
    procedure SpeedButton10Click(Sender: TObject);
    procedure SpeedButton11Click(Sender: TObject);
    Procedure BindAllMatreials;
    procedure destroyAllMaterials;
  private
    { Private declarations }
  public
    { Public declarations }
    DC : HDC;
    hrc: HGLRC;
    vp : TVector4i;
    Rotate:Boolean;
    Count,Rx,Ry,ViewAngelY,ViewAngelX:Integer;
    LigthPos:Array[0..3] of Glfloat;
    Curr,First:PSharic;
    SX,Sy,Angle,NS:Integer;
    Select:Boolean;
    Score:Integer;
  end;

Const
 MaxX:Integer=10;
 MaxY:Integer=10;
 GLF_START_LIST = 1000;
Type Material=Record
               Ambient:   Array[0..3] OF GLfloat;
               Diffuse:   Array[0..3] OF GLfloat;
               Specular:  Array[0..3] OF GLfloat;
               Emission:  Array[0..3] OF GLfloat;
               Shininess: GLubyte;
              End;
var
  MatID:GLuint;
  Stone: TStone;
  S,S1,S2:GlFloat;
  Been:Array[0..20,0..20] OF Integer;
  Table:Array[0..20,0..20] OF Boolean;
  ps : TPAINTSTRUCT;
  lf : TLOGFONT;
  hFontNew, hOldFont : HFONT;
  Way:String;
  Bx,By:Integer;
  MoveSound,DestrSound,GameS:TSongType;
  Time:Integer=0;
  ModelOut:Model;
  BackTexture,WooD:GLuint;
implementation

uses Math;

{$R *.DFM}

procedure TStone.FormDestroy(Sender: TObject);
begin
 glDeleteTextures(1,@BackTexture);
 CloseMusic(MoveSound);
 CloseMusic(DestrSound);
 CloseMusic(GameS);
 destroyAllMaterials;
 DellAll;
 glDeleteLists (GLF_START_LIST, 256);
 wglMakeCurrent(0, 0);
 wglDeleteContext(hrc);
 ReleaseDC (Handle, DC);
 DeleteDC (DC);
end;

procedure TStone.FormResize(Sender: TObject);
begin
 glViewport(0, 0, ClientWidth, ClientHeight);
 glScissor(0, 0, ClientWidth, ClientHeight);
 glMatrixMode(GL_PROJECTION);
 glLoadIdentity;
 gluPerspective(60, ClientWidth/ClientHeight, 0.01, 7);
 gluLookAt(0, 0, 3, 0, 0, 0, 0, 1, 0);
 glMatrixMode(GL_MODELVIEW);
 glLoadIdentity;
 glGetIntegerv(GL_VIEWPORT, @vp);
 ViewAngelY:=Random(30)+30;
 ViewAngelX:=Random(30)+30;
 glRotatef(ViewAngelY,1,0,0);
 glRotatef(ViewAngelX,0,1,0);
 InvalidateRect(Handle, nil, False);
end;

procedure TStone.FormCreate(Sender: TObject);
Var OPtions:TRCOptions; TextTemp:Pointer; W,H:Integer;
begin
 Randomize;
 Rotate:=False;
 InitOpenGL;
 DC := GetDC (Handle);
 Include(OPtions,opDoubleBuffered);
 hrc := CreateRenderingContext(DC,Options,32,16,0,0,0,0);
 ActivateRenderingContext(Dc,Hrc);
 //wglCreateContext(DC);
// wglMakeCurrent(DC, hrc);
//Инициализация текста
 WindowState:=wsMaximized;

 //Звук
 InitSound(Handle);
 OpenFile('Data\Sound\Move.Mp3',MoveSound);
 OpenFile('Data\Sound\Destr.Mp3',DestrSound);
 OpenFile('Data\Sound\GameOver.Mp3',GameS);
 //Модель
 InitModel('Data\Models\Sphere.Asc',ModelOut);
 CalcNormals(ModelOut);
 BuildLists(ModelOut);
 CreateTXT;
 glEnable(GL_SCISSOR_TEST);
 glEnable(GL_DEPTH_TEST);
 glEnable(GL_DITHER);
 glEnable(GL_LIGHTING);
 glEnable(GL_LIGHT0);
 LigthPos[0]:=0;  LigthPos[1]:=1.0;  LigthPos[2]:=0.0; LigthPos[3]:=1;
 glLightfv(Gl_LIGHT0,GL_POSITION,@LigthPos);
 glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, 0);
 glLightModeli(GL_LIGHT_MODEL_COLOR_CONTROL, GL_SEPARATE_SPECULAR_COLOR);
 glEnable(GL_NORMALIZE);
 glShadeModel(GL_Smooth);
 BindAllMatreials;
 glCallList(MatID);
//Подготовка текстуры заднего фона
 glGenTextures(1,@BackTexture);
 glGenTextures(1,@Wood);
 TextTemp:=LoadBmpFile('BackGround.Bmp', W, H);
  BindNewTexture(TextTemp,BackTexture,W,H);
 FreeMem(TextTemp);
 TextTemp:=LoadBmpFile('Wood.Bmp', W, H);
  BindNewTexture(TextTemp,Wood,W,H);
 FreeMem(TextTemp);
 ViewAngelY:=0; ViewAngelX:=0;
 NewG;
end;

procedure TStone.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 Rotate:=True;
 RX:=X; RY:=Y;

end;

procedure TStone.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 Rotate:=False;
 FormClick(Application);
end;

procedure TStone.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
 IF Rotate Then
  Begin
   GlRotateF(-ViewAngelX,0,1,0);
   GlRotateF(-ViewAngelY,1,0,0);
   ViewAngelY:=ViewAngelY+Y-Ry;
   ViewAngelX:=ViewAngelX+X-RX;
   If ViewAngelY>90 then ViewAngelY:=90;
   If ViewAngelY<10 then ViewAngelY:=10;
   GlRotateF(ViewAngelY,1,0,0);
   GlRotateF(ViewAngelX,0,1,0);
   InvalidateRect(Handle,Nil,False);
  End;
 RX:=X;
 RY:=Y;
end;

procedure TStone.FormPaint(Sender: TObject);
begin
 glPushMatrix;
 glClear (GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);      // очистка буфера цвета
 glLightfv(Gl_LIGHT0,GL_POSITION,@LigthPos);
  // PaintModel(0,0,0,ModelOut);
   DrawPlant(MaxX,MaxY);
   PaintAll;
   glLoadIdentity;
   glTranslatef(-1,1.2,0.5);
   glScalef(0.35,0.35,0.35);
   glEnable(GL_COLOR_MATERIAL);
   glColor3f(1,1,1);
   Outtext(Pchar('Вы набрали - '+Inttostr(Score)+'!'));
   glDisable(GL_COLOR_MATERIAL);
 SwapBuffers(Dc);
 glPopMatrix;
 If (Select) Then InvalidateRect(Handle,Nil,False);
end;

procedure TStone.DrawPlant(MaxX, MaxY: Integer);
Var X,Y:Integer; Left,Top:GlFloat;
    Sph:PGLUQuadric;
begin
 Left:=-MaxX*0.13;
 Top:=-MaxY*0.13;
 //Изменение цвета выделенной клетки
 glCallList(MatID);

 glDisable(GL_COLOR_MATERIAL);
 GlBegin(Gl_quads);
 For Y:=0 To MaxY-1 Do
  For X:=0 To MaxX-1 Do
   Begin
    glNormal3f(0,1,0);
    GlVertex3f(Left+0.25*X+0.01*X,0,Top+0.25*Y+0.01*Y);
    GlVertex3f(Left+0.25*(X+1)+0.01*X,0,Top+0.25*Y+0.01*Y);
    GlVertex3f(Left+0.25*(X+1)+0.01*X,0,Top+0.25*(Y+1)+0.01*Y);
    GlVertex3f(Left+0.25*X+0.01*X,0,Top+0.25*(Y+1)+0.01*Y);
   End;
 GlEnd;
//Задний фон
 glEnable(GL_TEXTURE_2D);
 glBindTexture(GL_TEXTURE_2D, BackTexture);
 Sph:=gluNewQuadric;
 gluQuadricOrientation(sph,GLU_INSIDE);
 gluQuadricTexture(sph,True);
 gluSphere(Sph,3.8,15,15);
 gluDeleteQuadric(Sph);
//----------
 glBindTexture(GL_TEXTURE_2D, Wood);
 glCallList(MatID+2);
 GlBegin(Gl_quads);
  glNormal3f(0,1,0);
  glTexCoord2f(0,0);
  GlVertex3f(Left-0.02,-0.01,Top-0.02);
  glTexCoord2f(4,0);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.01,Top-0.02);
  glTexCoord2f(4,4);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.01,Top+0.25*MaxY+0.01*Y+0.01);
  glTexCoord2f(0,4);
  GlVertex3f(Left-0.02,-0.01,Top+0.25*MaxY+0.01*Y+0.01);
  glNormal3f(0,0,1);
  glTexCoord2f(0,0);
  GlVertex3f(Left-0.02,-0.1,Top-0.02);
  glTexCoord2f(3,0);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.1,Top-0.02);
  glTexCoord2f(3,0.4);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.01,Top-0.02);
  glTexCoord2f(0,0.4);
  GlVertex3f(Left-0.02,-0.01,Top-0.02);
  glNormal3f(0,0,-1);
  glTexCoord2f(0,0);
  GlVertex3f(Left-0.02,-0.1,Top+0.25*MaxY+0.01*Y+0.01);
  glTexCoord2f(3,0);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.1,Top+0.25*MaxY+0.01*Y+0.01);
  glTexCoord2f(3,0.4);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.01,Top+0.25*MaxY+0.01*Y+0.01);
  glTexCoord2f(0,0.4);
  GlVertex3f(Left-0.02,-0.01,Top+0.25*MaxY+0.01*Y+0.01);
  glNormal3f(1,0,0);
  glTexCoord2f(3,0);
  GlVertex3f(Left-0.02,-0.01,Top-0.02);
  glTexCoord2f(3,0.4);
  GlVertex3f(Left-0.02,-0.1,Top-0.02);
  glTexCoord2f(0,0.4);
  GlVertex3f(Left-0.02,-0.1,Top+0.25*MaxY+0.01*Y+0.01);
  glTexCoord2f(0,0);
  GlVertex3f(Left-0.02,-0.01,Top+0.25*MaxY+0.01*Y+0.01);
  glNormal3f(-1,0,0);
  glTexCoord2f(3,0);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.01,Top-0.02);
  glTexCoord2f(3,0.4);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.1,Top-0.02);
  glTexCoord2f(0,0.4);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.1,Top+0.25*MaxY+0.01*Y+0.01);
  glTexCoord2f(0,0);
  GlVertex3f(Left+0.25*MaxX+0.01*X+0.01,-0.01,Top+0.25*MaxY+0.01*Y+0.01);
 GlEnd;
 glDisable(GL_TEXTURE_2D);
end;

procedure TStone.DrawQuadSph(Rad, Segsx, Segsy: Glfloat);
begin
 PaintModel(ModelOut);
end;

procedure TStone.NewSH(X, Y: Integer);
Var Prev,Newest:Psharic;
begin
 If Count=0 Then
  Begin
   New(Newest);
   First:=Newest;
  End
 Else
  Begin
   Prev:=First;
   While Prev^.Next<>Nil Do Prev:=Prev^.Next;
   New(Newest);
   Prev^.Next:=Newest;
  End;
   While Table[X,Y]<>False Do
    Begin
     X:=Random(MaXX);
     Y:=Random(MaxY)
    End;
 Table[X,Y]:=True;
 Newest^.SX:=X; Newest^.SY:=Y;
 Newest^.Selected:=False;
 Newest^.Material:=Random(6)+1;
 Newest^.Next:=Nil;
 InC(Count);
end;

procedure TStone.DellAll;
Var Temp:Psharic;
begin
 If Count<>0 Then
 While First^.Next <> Nil Do
  Begin
   Temp:=FirsT^.Next;
   Dispose(First);
   First:=Temp;
  End;
 Count:=0;
end;

procedure TStone.PaintAll;
Var X,Y{,K}:Integer; {PX,PY,PosX,Posy,Rad:GlFloat;} Selec:Boolean; TCurr:PSharic;
begin
 glCallList(MatID+2);
 Tcurr:=First;
 glTranslatef(0,0.09,0);
// K:=0;
 IF Count<>0 Then
 Begin
  While Tcurr^.Next<>Nil Do
   Begin
//    Inc(k);
    X:=Tcurr^.SX; Y:=Tcurr^.SY;

    Selec:=False;

    glCallList(MatID+Tcurr^.Material);

    If (X=Sx)And(Y=Sy) Then Selec:=true;

    DrawIN(0.1,X,Y,Selec);

    Tcurr:=Tcurr^.Next;

   End;
  //Inc(K);
  X:=Tcurr^.SX; Y:=Tcurr^.SY;
  Selec:=False;

  glCallList(MatID+Tcurr^.Material);

  If (Tcurr^.Sx=Sx)And(Tcurr^.Sy=Sy) Then Selec:=True;

  DrawIN(0.1,X,Y,Selec);
 End;
 glTranslatef(0,-0.09,0);
 //Outtext(Pchar(Inttostr(K)+'/'+Inttostr(Count)));
end;

procedure TStone.FormClick(Sender: TObject);
Var
 //Viewport : Array [0..3] of GLInt;
 mvMatrix, ProjMatrix : TGLMatrixd4;//T16dArray;
 RealY : GLint ;          // позиция OpenGL y - координаты
 wx, wy, wz : GLdouble ;  // возвращаемые мировые x, y, z координаты
 Zval : GLfloat;
 PX,PY,I,G:Integer;
 PreSel:Boolean;
begin
 If (Rotate = False)And(Not Moving.Enabled) Then
  Begin
 //  Done:=False;
   glGetIntegerv (GL_VIEWPORT, @VP);
   glGetDoublev (GL_MODELVIEW_MATRIX, @mvMatrix);
   glGetDoublev (GL_PROJECTION_MATRIX, @ProjMatrix);
   // viewport[3] - высота окна в пикселях
   RealY := vp[3] - RY - 1;

   glReadPixels(RX, RealY, 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, @Zval);

   gluUnProject (RX, RealY, Zval,
                  mvMatrix, ProjMatrix, Vp, @wx, @wy, @wz);

   PX:=SX;
   pY:=SY;
   SX:=Round((WX+MAXX*0.13-0.25/2)/0.26);
   SY:=Round((WZ+MAXY*0.13-0.25/2)/0.26);
   PreSel:=Select;
   FindSelected;
   If (not Select)And(PreSel) Then
    Begin
     For I:=0 To MaxY-1 Do
      For G:=0 To MaxX-1 Do
       Begin
        Been[I,G]:=1000;
        If Table[I,G] Then Been[I,G]:=-1;
       End;

     FindWay(PX,PY,SX,SY,0);

     If (Been[SX,SY]>0)And(Been[Sx,Sy]<1000) Then
      Begin
       Way:=Selectway(SX,Sy);
       Bx:=Px; By:=Py;
       Sx:=-1; Sy:=-1;
       Moving.Enabled:=True;
      End;
    End
  End;
 InvalidateRect(Handle,Nil,False);
end;

procedure TStone.DrawCirc(Rad: Glfloat; Segs: Integer);
Var CurrPt:Integer; //LastP:GlFloat;
begin
 glBegin(GL_TRIANGLES);
 For CurrPt:=0 To segs-1 Do
  Begin
   glVertex3f(0,0,0);
   glVertex3f(Cos(2*Pi*CurrPt/Segs)*Rad,0,Sin(2*Pi*CurrPt/Segs)*Rad);
   glVertex3f(Cos(2*Pi*(CurrPt+1)/Segs)*Rad,0,Sin(2*Pi*(CurrPt+1)/Segs)*Rad);
  End;
 GlEnd;
end;

Procedure TStone.FindSelected;
Var TCurr:PSharic;
begin
 Tcurr:=First;
 IF Count<>0 Then
  Begin
   While ((SX<>Tcurr^.SX)OR(SY<>Tcurr^.SY))AND(Tcurr^.Next<>Nil) Do Tcurr:=Tcurr^.Next;
   If (SX=Tcurr^.SX)And(SY=Tcurr^.SY) Then
    Begin
     Select:=True;
    End
   Else Begin Select:=False; NS:=-1; End;
  End;
end;

procedure TStone.DrawIn(Rad:Glfloat;  X, Y: Integer; Sel:Boolean);
Var PosX,PosY,Ra:GlFloat;
begin
 PosX:=-MaxX*0.13+0.26*X+0.25/2;
 PosY:=-MaxY*0.13+0.26*Y+0.25/2;
 glTranslated(PosX,0,PosY);

 Ra:=0;

 If Sel Then
  Begin
   Angle:=Angle+16;
   IF Angle>360 Then Angle:=0;
   glRotatef(Angle,0,1,0);
   Ra:=0.05;
   glTranslatef(0.0,0.05,0.0);
  End;
 DrawQuadSph(Rad+Ra,20,20);
 If Sel Then
  Begin
   glRotatef(-Angle,0,1,0);
   glTranslatef(0.0,-0.05,0.0);
  End;
 //Тень
 glColor3f(0.2,0.2,0.2);
 glDisable(GL_LIGHTING);
 glTranslatef(0,-0.089,0);
 DrawCirc(Rad+Ra/2,25);
 glTranslatef(0,0.089,0);
 glEnable(GL_LIGHTING);

 glTranslated(-PosX,0,-Posy);
end;

procedure TStone.MoveTo(X, Y, EX, Ey: Integer);
Var TCurr:PSharic;
begin
 TCurr:=First;
 IF Count<>0 Then
  Begin
   While ((X<>TCurr^.SX)OR(Y<>TCurr^.SY))AND(TCurr^.Next<>Nil) Do TCurr:=TCurr^.Next;
   If (X=TCurr^.SX)And(Y=TCurr^.SY) Then
    Begin
     Table[X,Y]:=False;
     TCurr^.SX:=Ex;
     TCurr^.SY:=Ey;
     Table[EX,EY]:=True;
    End;
  End;
end;

Procedure TStone.FindWay(X, Y, EX, Ey, N: Integer);
begin
 Been[X,Y]:=N;
 If (Been[X+1,Y]>N+1)And(X+1<=MaXX-1) Then FindWay(X+1, Y, EX, Ey, N+1);
 If (Been[X-1,Y]>N+1)And(X-1>=0)      Then FindWay(X-1, Y, EX, Ey, N+1);
 If (Been[X,Y+1]>N+1)And(Y+1<=MaXY-1) Then FindWay(X, Y+1, EX, Ey, N+1);
 If (Been[X,Y-1]>N+1)And(Y-1>=0)      Then FindWay(X, Y-1, EX, Ey, N+1);
end;

Function TStone.KillSome:Boolean;
Var X,Y,I,Countr,color:Integer;
begin
 //горизонталь
 Result:=False;
 For Y:=0 to MaxY-1 Do
  Begin
   Countr:=0;
   For X:=0 to MaxX-2 Do
   If Table[X,Y]<>False Then
    If (GetColor(X,Y)=GetColor(X+1,Y))And(X<>MaxX-2) Then Inc(Countr)
    Else
     Begin
      If (X=MaxX-2)And(GetColor(X,Y)=GetColor(X+1,Y)) Then Inc(Countr);
      If Countr<4 Then Countr:=0
      Else Begin
//               For I:=X+1 Downto X-Countr Do Kill(I,Y)
//              Else
               Color:=GetColor(X,Y);
               For I:=X+1 Downto X-Countr-1 Do
                If (Color=GetColor(I,Y)) Then
                 Kill(I,Y);
              Score:=Score+Countr+(50 div MaxX);
              Result:=True;
              Countr:=0;
           End;
     End;
  End;
 //Вертикаль
 For X:=0 to MaxX-1 Do
  Begin
   Countr:=0;
   For Y:=0 to MaxY-2 Do
   If Table[X,Y]<>False Then
    If (GetColor(X,Y)=GetColor(X,Y+1))And(Y<>MaxY-2) Then Inc(Countr)
    Else
     Begin
      If (Y=MaxY-2)And(GetColor(X,Y)=GetColor(X,Y+1)) Then Inc(Countr);
      If Countr<4 Then Countr:=0
      Else Begin
//              If (GetColor(X,Y)=GetColor(X,Y+1)) Then
//               For I:=Y+1 Downto Y-Countr Do Kill(X,I)
//              Else
              Color:=GetColor(X,Y);
              For I:=Y+1 Downto Y-Countr Do
               If (Color=GetColor(X,I)) Then
                Kill(X,I);
              Score:=Score+Countr+(50 div MaxY);
              Result:=True;
              Countr:=0;
           End;
     End;
  End;
end;

function TStone.GetColor(X, Y: Integer): Integer;
Var TCurr:PSharic;
begin
 Result:=-1;
 TCurr:=First;
 IF Count<>0 Then
  Begin
   While ((X<>TCurr^.SX)OR(Y<>TCurr^.SY))AND(TCurr^.Next<>Nil) Do TCurr:=TCurr^.Next;
   IF (X=TCurr^.SX)And(Y=TCurr^.SY) Then Result:=Tcurr^.Material;//???---???
  End;
end;

procedure TStone.Kill(X, Y:Integer);
Var TCurr,PreV:PSharic;
begin
 TCurr:=First;
 IF (Count<>0) Then
 Begin
 If (X<>TCurr^.SX)OR(Y<>TCurr^.SY) Then
  Begin
   While ((X<>TCurr^.SX)OR(Y<>TCurr^.SY))AND(TCurr^.Next<>Nil) Do Begin Prev:=Tcurr; TCurr:=TCurr^.Next; End;
   If (X=TCurr^.SX)And(Y=TCurr^.SY) Then
    Begin
     Prev^.Next:=TCurr^.Next;
     Dispose(Tcurr);
     Table[X,Y]:=False;
     Count:=Count-1;
    End;
  End
 Else
  Begin
   First:=TCurr^.Next;
   Dispose(Tcurr);
   Table[X,Y]:=False;
   Count:=Count-1;
  End;
 End;
end;

procedure TStone.newG;
Var X,Y:Integer;
begin
 DellAll;
 Select:=False;
 Count:=0;Score:=0;
// SetLength(Table,MaxX,MaxY);
// SetLength(Been,MaxX,MaxY);
 For X:=0 To MaxX-1 Do
  For Y:=0 To MaxY-1 Do Table[x,y]:=False;
 //Создание 3-х первых шаров
 S:=0; S1:=0; S2:=0;  Angle:=0; NS:=-1; //Ways:='';
 NewSH(Random(MaxX),Random(MaxY));
 NewSH(Random(MaxX),Random(MaxY));
 NewSH(Random(MaxX),Random(MaxY));
 InvalidateRect(Handle,Nil,False);
end;

procedure TStone.NewGaClick(Sender: TObject);
begin
 NewG;
end;

procedure TStone.N1Click(Sender: TObject);
begin
 Inc(MaxX);
 If MaxX>20 Then MaxX:=20;
 Newg;
end;

procedure TStone.N4Click(Sender: TObject);
begin
 Inc(MaxY);
 If MaxY>20 Then MaxY:=20;
 Newg;
end;

procedure TStone.N2Click(Sender: TObject);
begin
 Dec(MaxX);
 If MaxX<5 Then MaxX:=5;
 Newg;
end;

procedure TStone.N5Click(Sender: TObject);
begin
 Dec(MaxY);
 If MaxY<5 Then MaxY:=5;
 Newg;
end;

procedure TStone.Outtext(TXT: Pchar);
begin
 glListBase(GLF_START_LIST);
 glCallLists(Length(Txt),GL_UNSIGNED_BYTE, TXT);
end;

procedure TStone.CreateTXT;
begin
 // подготовка вывода текста
FillChar(lf, SizeOf(lf), 0);
lf.lfHeight               :=   -28 ;
lf.lfWeight               :=   FW_NORMAL ;
lf.lfCharSet              :=   ANSI_CHARSET ;
lf.lfOutPrecision         :=   OUT_DEFAULT_PRECIS ;
lf.lfClipPrecision        :=   CLIP_DEFAULT_PRECIS ;
lf.lfQuality              :=   DEFAULT_QUALITY ;
lf.lfPitchAndFamily       :=   FF_DONTCARE OR DEFAULT_PITCH;
lstrcpy (lf.lfFaceName, 'Times New Roman Cyr') ;

hFontNew := CreateFontIndirect(lf);
hOldFont := SelectObject(DC,hFontNew);

wglUseFontOutlines(DC, 0, 255, GLF_START_LIST, 0.0, 0.1,
                   WGL_FONT_POLYGONS, nil);

DeleteObject(SelectObject(DC,hOldFont));
DeleteObject(SelectObject(DC,hFontNew));
end;

procedure TStone.SpeedButton5Click(Sender: TObject);
begin
 InitModel('Data\Models\Sphere.Asc',ModelOut);
 CalcNormals(ModelOut);
 BuildLists(ModelOut);
 InvalidateRect(Handle,nil,False);
end;

procedure TStone.SpeedButton6Click(Sender: TObject);
begin
 InitModel('Data\Models\Cube.Asc',ModelOut);
 CalcNormals(ModelOut);
 BuildLists(ModelOut);
 InvalidateRect(Handle,nil,False);
end;

procedure TStone.SpeedButton7Click(Sender: TObject);
begin
 InitModel('Data\Models\Cone.Asc',ModelOut);
 CalcNormals(ModelOut);
 BuildLists(ModelOut);
 InvalidateRect(Handle,nil,False);
end;

procedure TStone.SpeedButton8Click(Sender: TObject);
begin
 InitModel('Data\Models\Torus.Asc',ModelOut);
 CalcNormals(ModelOut);
 BuildLists(ModelOut);
 InvalidateRect(Handle,nil,False);
end;

procedure TStone.SpeedButton9Click(Sender: TObject);
begin
 InitModel('Data\Models\Teapot.Asc',ModelOut);
 CalcNormals(ModelOut);
 BuildLists(ModelOut);
 InvalidateRect(Handle,nil,False);
end;

function TStone.Selectway(X,Y:Integer): String;
Var N,I:Integer; S:String[1];
begin
 Result:=IntToStr(X)+'/'+IntToStr(Y)+'\';
 N:=Been[X,Y];
 For I:=1 to N do
  Begin
   If (X+1<MaxX)And(Been[X+1,Y]=Been[X,Y]-1) Then Begin X:=X+1; Result:=Result+IntToStr(X)+'/'+IntToStr(Y)+'\'; End
   Else
   If (X-1>=0)And(Been[X-1,Y]=Been[X,Y]-1) Then Begin X:=X-1; Result:=Result+IntToStr(X)+'/'+IntToStr(Y)+'\'; End
   Else
   If (Y+1<MaxY)And(Been[X,Y+1]=Been[X,Y]-1) Then Begin Y:=Y+1; Result:=Result+IntToStr(X)+'/'+IntToStr(Y)+'\'; End
   Else
   If (Y-1>=0)And(Been[X,Y-1]=Been[X,Y]-1) Then Begin Y:=Y-1; Result:=Result+IntToStr(X)+'/'+IntToStr(Y)+'\'; End
  End;
 For N:=1 To Length(Result) Div 2 Do
  Begin
   S[1]:=Result[N];
   Result[N]:=Result[Length(Result)-N+1];
   Result[Length(Result)-N+1]:=S[1];
  End;
 Delete(Result,1,1);
 Result:=Result+'\';
end;

procedure TStone.MovingTimer(Sender: TObject);
Var F:String;
begin
 If Way<>'' Then
  Begin
   F:=Copy(Way,1,pos('\',Way)-1);
   Delete(Way,1,Pos('\',Way));
   PlayAndStop(MoveSound);
   MoveTo(Bx,By,
          StrToInt(Copy(F,Pos('/',F)+1,Length(F)-Pos('/',F))),
          StrToInt(Copy(F,1,Pos('/',F)-1)));
   By:=StrToInt(Copy(F,1,Pos('/',F)-1));
   Bx:=StrToInt(Copy(F,Pos('/',F)+1,Length(F)-Pos('/',F)));
   InvalidateRect(Handle,Nil,False);
  End
 Else
  Begin
   Moving.Enabled:=False;
   AfterMoving;
   InvalidateRect(Handle,Nil,False);
  End
end;

procedure TStone.AfterMoving;
Var Done:Boolean; SS:String; Fil:Textfile;
begin
 If not KillSome Then
  Begin
   Done:=False;
   If Count<MaxX*MaxY Then NewSH(Random(MaxX),Random(MaxY))
   Else Done:=True;
   If Count<MaxX*MaxY Then NewSH(Random(MaxX),Random(MaxY))
   Else Done:=True;
   If Count<MaxX*MaxY Then NewSH(Random(MaxX),Random(MaxY))
   Else Done:=True;
   If Count>=MaxX*MaxY Then Done:=True;
   If Done Then
    Begin
     PlayAndStop(GameS);
     Showmessage('Игра окончена, вы набрали: '+inttostr(Score)+' очков!');
     AssignFile(Fil,'Score.Top');
     Reset(Fil);
     Readln(Fil,Ss);
     CloseFile(Fil);
     If Score>StrToInt(SS) Then
      Begin
       Showmessage('Вы побили рекорд - '+Ss+'!');
       AssignFile(Fil,'Score.Top');
       Rewrite(Fil);
       Writeln(Fil,Inttostr(Score));
       CloseFile(Fil);
      End
     Else Showmessage('Рекорд - '+Ss+'!');
    End;
   End
 Else PlayAndStop(DestrSound);
end;

procedure TStone.SpeedButton10Click(Sender: TObject);
begin
 InitModel('Data\Models\Knot.Asc',ModelOut);
 CalcNormals(ModelOut);
 BuildLists(ModelOut);
 InvalidateRect(Handle,Nil,False);
end;

procedure TStone.SpeedButton11Click(Sender: TObject);
begin
 If (OpenDialog1.Execute) Then
  Begin
   InitModel(OpenDialog1.FileName,ModelOut);
   CalcNormals(ModelOut);
   BuildLists(ModelOut);
   InvalidateRect(Handle,Nil,False);
  End;
end;

procedure TStone.BindAllMatreials;
Var Mat:Material;
begin
 MatID:=glGenLists(7);
 //Доска
 Mat.Ambient[0]:=0.05;  Mat.Ambient[1]:=0.05;  Mat.Ambient[2]:=0.07;  Mat.Ambient[3]:=0.82;
 Mat.Diffuse[0]:=0.18;  Mat.Diffuse[1]:=0.17;  Mat.Diffuse[2]:=0.16;  Mat.Diffuse[3]:=0.82;
 Mat.Specular[0]:=0.33;  Mat.Specular[1]:=0.33;  Mat.Specular[2]:=0.35;  Mat.Specular[3]:=0.82;
 Mat.Emission[0]:=0.05;  Mat.Emission[1]:=0.05;  Mat.Emission[2]:=0.05;  Mat.Emission[3]:=0.00;
 Mat.Shininess:=38;
 glNewList(MatID,GL_COMPILE);
  glMaterialfv(GL_FRONT,GL_AMBIENT, @MAT.Ambient);
  glMaterialfv(GL_FRONT,GL_DIFFUSE, @MAT.Diffuse);
  glMaterialfv(GL_FRONT,GL_SPECULAR, @MAT.Specular);
  glMaterialfv(GL_FRONT,GL_EMISSION, @MAT.Emission);
  glMateriali(GL_FRONT,GL_SHININESS, Mat.Shininess);
 glEndList;
 //Красный
 Mat.Ambient[0]:=0.17;  Mat.Ambient[1]:=0.01;  Mat.Ambient[2]:=0.01;  Mat.Ambient[3]:=0.55;
 Mat.Diffuse[0]:=0.61;  Mat.Diffuse[1]:=0.04;  Mat.Diffuse[2]:=0.04;  Mat.Diffuse[3]:=0.55;
 Mat.Specular[0]:=0.73;  Mat.Specular[1]:=0.63;  Mat.Specular[2]:=0.63;  Mat.Specular[3]:=0.55;
 Mat.Emission[0]:=0.00;  Mat.Emission[1]:=0.00;  Mat.Emission[2]:=0.00;  Mat.Emission[3]:=0.00;
 Mat.Shininess:=77;
 glNewList(MatID+1,GL_COMPILE);
  glMaterialfv(GL_FRONT,GL_AMBIENT, @MAT.Ambient);
  glMaterialfv(GL_FRONT,GL_DIFFUSE, @MAT.Diffuse);
  glMaterialfv(GL_FRONT,GL_SPECULAR, @MAT.Specular);
  glMaterialfv(GL_FRONT,GL_EMISSION, @MAT.Emission);
  glMateriali(GL_FRONT,GL_SHININESS, Mat.Shininess);
 glEndList;
 //Желтый
 Mat.Ambient[0]:=0.33;  Mat.Ambient[1]:=0.22;  Mat.Ambient[2]:=0.03;  Mat.Ambient[3]:=1.00;
 Mat.Diffuse[0]:=0.78;  Mat.Diffuse[1]:=0.57;  Mat.Diffuse[2]:=0.11;  Mat.Diffuse[3]:=1.00;
 Mat.Specular[0]:=0.99;  Mat.Specular[1]:=0.94;  Mat.Specular[2]:=0.81;  Mat.Specular[3]:=1.00;
 Mat.Emission[0]:=0.00;  Mat.Emission[1]:=0.00;  Mat.Emission[2]:=0.00;  Mat.Emission[3]:=0.00;
 Mat.Shininess:=28;
 glNewList(MatID+2,GL_COMPILE);
  glMaterialfv(GL_FRONT,GL_AMBIENT, @MAT.Ambient);
  glMaterialfv(GL_FRONT,GL_DIFFUSE, @MAT.Diffuse);
  glMaterialfv(GL_FRONT,GL_SPECULAR, @MAT.Specular);
  glMaterialfv(GL_FRONT,GL_EMISSION, @MAT.Emission);
  glMateriali(GL_FRONT,GL_SHININESS, Mat.Shininess);
 glEndList;
 //Зеленый
 Mat.Ambient[0]:=0.02;  Mat.Ambient[1]:=0.17;  Mat.Ambient[2]:=0.02;  Mat.Ambient[3]:=0.55;
 Mat.Diffuse[0]:=0.08;  Mat.Diffuse[1]:=0.61;  Mat.Diffuse[2]:=0.08;  Mat.Diffuse[3]:=0.55;
 Mat.Specular[0]:=0.63;  Mat.Specular[1]:=0.73;  Mat.Specular[2]:=0.63;  Mat.Specular[3]:=0.55;
 Mat.Emission[0]:=0.00;  Mat.Emission[1]:=0.00;  Mat.Emission[2]:=0.00;  Mat.Emission[3]:=0.00;
 Mat.Shininess:=77;
 glNewList(MatID+3,GL_COMPILE);
  glMaterialfv(GL_FRONT,GL_AMBIENT, @MAT.Ambient);
  glMaterialfv(GL_FRONT,GL_DIFFUSE, @MAT.Diffuse);
  glMaterialfv(GL_FRONT,GL_SPECULAR, @MAT.Specular);
  glMaterialfv(GL_FRONT,GL_EMISSION, @MAT.Emission);
  glMateriali(GL_FRONT,GL_SHININESS, Mat.Shininess);
 glEndList;
 //Синий
 Mat.Ambient[0]:=0.10;  Mat.Ambient[1]:=0.14;  Mat.Ambient[2]:=0.17;  Mat.Ambient[3]:=0.80;
 Mat.Diffuse[0]:=0.40;  Mat.Diffuse[1]:=0.40;  Mat.Diffuse[2]:=0.74;  Mat.Diffuse[3]:=0.80;
 Mat.Specular[0]:=0.60;  Mat.Specular[1]:=0.73;  Mat.Specular[2]:=0.8;  Mat.Specular[3]:=0.80;
 Mat.Emission[0]:=0.00;  Mat.Emission[1]:=0.00;  Mat.Emission[2]:=0.00;  Mat.Emission[3]:=0.00;
 Mat.Shininess:=77;
 glNewList(MatID+4,GL_COMPILE);
  glMaterialfv(GL_FRONT,GL_AMBIENT, @MAT.Ambient);
  glMaterialfv(GL_FRONT,GL_DIFFUSE, @MAT.Diffuse);
  glMaterialfv(GL_FRONT,GL_SPECULAR, @MAT.Specular);
  glMaterialfv(GL_FRONT,GL_EMISSION, @MAT.Emission);
  glMateriali(GL_FRONT,GL_SHININESS, Mat.Shininess);
 glEndList;
 //Белый
 Mat.Ambient[0]:=0.00;  Mat.Ambient[1]:=0.00;  Mat.Ambient[2]:=0.00;  Mat.Ambient[3]:=1.00;
 Mat.Diffuse[0]:=0.81;  Mat.Diffuse[1]:=0.81;  Mat.Diffuse[2]:=0.81;  Mat.Diffuse[3]:=1.00;
 Mat.Specular[0]:=0.73;  Mat.Specular[1]:=0.73;  Mat.Specular[2]:=0.73; Mat.Specular[3]:=1.00;
 Mat.Emission[0]:=0.00;  Mat.Emission[1]:=0.00;  Mat.Emission[2]:=0.00;  Mat.Emission[3]:=0.00;
 Mat.Shininess:=32;
 glNewList(MatID+5,GL_COMPILE);
  glMaterialfv(GL_FRONT,GL_AMBIENT, @MAT.Ambient);
  glMaterialfv(GL_FRONT,GL_DIFFUSE, @MAT.Diffuse);
  glMaterialfv(GL_FRONT,GL_SPECULAR, @MAT.Specular);
  glMaterialfv(GL_FRONT,GL_EMISSION, @MAT.Emission);
  glMateriali(GL_FRONT,GL_SHININESS, Mat.Shininess);
 glEndList;
 //Черный
 Mat.Ambient[0]:=0.00;  Mat.Ambient[1]:=0.00;  Mat.Ambient[2]:=0.00;  Mat.Ambient[3]:=1.00;
 Mat.Diffuse[0]:=0.01;  Mat.Diffuse[1]:=0.01;  Mat.Diffuse[2]:=0.01;  Mat.Diffuse[3]:=1.00;
 Mat.Specular[0]:=0.73;  Mat.Specular[1]:=0.73;  Mat.Specular[2]:=0.73; Mat.Specular[3]:=1.00;
 Mat.Emission[0]:=0.10;  Mat.Emission[1]:=0.10;  Mat.Emission[2]:=0.10;  Mat.Emission[3]:=0.00;
 Mat.Shininess:=32;
 glNewList(MatID+6,GL_COMPILE);
  glMaterialfv(GL_FRONT,GL_AMBIENT, @MAT.Ambient);
  glMaterialfv(GL_FRONT,GL_DIFFUSE, @MAT.Diffuse);
  glMaterialfv(GL_FRONT,GL_SPECULAR, @MAT.Specular);
  glMaterialfv(GL_FRONT,GL_EMISSION, @MAT.Emission);
  glMateriali(GL_FRONT,GL_SHININESS, Mat.Shininess);
 glEndList;
end;

procedure TStone.DestroyAllMaterials;
begin
 glDeleteLists(MatID,7);
end;

end.
