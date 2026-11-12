unit Models;

interface
 Uses OpenGl15;
 Type Model=Record
             Vertex,NormalsV:Array Of Array[0..2] Of GlFloat;
             VertexBuild,NormalMap:Array Of Array[0..2] Of GlFloat;
             Trian:Array of array[0..2] Of Integer;
             Trans:GLfloat;
            End;

 Function InitModel(FileAndPath:String; Var ModelUp:Model):String;
 Procedure PaintModel(ModelUp:Model);
 Procedure CalcNormals(Var ModelUp:Model);
 Procedure BuildLists(Var ModelUp:Model);

implementation
 Uses SysUtils;
 //Облегченный метод чтения Asc файлов учитывает только 1 поверхность
 Function InitModel(FileAndPath:String; Var ModelUp:Model):String;
  Var InFile:TextFile; Str:String; I,J:Integer; Point:String[1];
      MaxX,MaxY,MaxZ,MinX,MinY,MinZ:Glfloat;
  Begin
   MaxX:=0; MaxY:=0; MaxZ:=0;
   MinX:=0; MinY:=0; MinZ:=0;
   AssignFile(InFile,FileAndPath);
   Reset(InFile);
   //Определение кол-ва вершин и треугольников
   Repeat
    Readln(InFile,Str);
   Until pos('Vertices:',Str)<>0;
   Setlength(ModelUp.Vertex,Strtoint(Copy(Str,pos('Vertices:',Str)+10,Pos(' ',Copy(Str,pos('Vertices:',Str)+10,15))-1)));
   Setlength(ModelUp.NormalsV,Strtoint(Copy(Str,pos('Vertices:',Str)+10,Pos(' ',Copy(Str,pos('Vertices:',Str)+10,15))-1)));
   Setlength(ModelUp.Trian,Strtoint(Copy(Str,pos('Faces:',Str)+7,Length(Str))));
   //Занесения координат вершин в массив модели
   Repeat
    Readln(InFile,Str);
   Until pos('Vertex',Str)<>0;
   For I:= 0 to Length(ModelUp.Vertex)-1 Do
    Begin
     Readln(InFile,Str);
     Point:=Copy(FloatTostr(0.1),2,1);
     If Pos(Point[1],Str)=0 Then
      For J:=1 To Length(Str) Do
       If (Str[J]='.')Or(Str[J]=',') Then Str[J]:=Point[1];
     Delete(Str,1,Pos('X',Str)+1);
     ModelUp.Vertex[I,0]:=StrToFloat(Copy(Str,1,Pos(' ',Str)-1));
     Delete(Str,1,Pos('Y',Str)+1);
     ModelUp.Vertex[I,1]:=StrToFloat(Copy(Str,1,Pos(' ',Str)-1));
     Delete(Str,1,Pos('Z',Str)+1);
     Str:=Str+' ';
     ModelUp.Vertex[I,2]:=StrToFloat(Copy(Str,1,Pos(' ',Str)-1));
     IF ModelUp.Vertex[I,0]>MaxX Then MaxX:=ModelUp.Vertex[I,0]
     Else IF ModelUp.Vertex[I,0]<MinX Then MinX:=ModelUp.Vertex[I,0];
     IF ModelUp.Vertex[I,1]>MaxY Then MaxY:=ModelUp.Vertex[I,1]
     Else IF ModelUp.Vertex[I,1]<MinY Then MinY:=ModelUp.Vertex[I,1];
     IF ModelUp.Vertex[I,2]>MaxZ Then MaxZ:=ModelUp.Vertex[I,2]
     Else IF ModelUp.Vertex[I,2]<MinZ Then MinZ:=ModelUp.Vertex[I,2];
    End;
    MaxX:=MaxX-MinX;
    MaxY:=MaxY-MinY;
    MaxZ:=MaxZ-MinZ;
//    If (MaxX>=MaxZ)And(MaxX>=MaxZ) Then MinZ:=MaxX;
    If (MaxX>=MaxY) Then MinZ:=MaxX
    Else MinZ:=MaxY;
//    If (MaxY>=MaxZ)And(MaxY>=MaxX) Then MinZ:=MaxY;
//    If (MaxZ>=MaxY)And(MaxZ>=MaxX) Then MinZ:=MaxZ;
    MinZ:=MinZ*4.2;
    ModelUp.Trans:=0;
   For I:=0 To Length(ModelUp.Vertex)-1 Do
    Begin
     ModelUp.Vertex[I,0]:=ModelUp.Vertex[I,0]/MinZ;
     ModelUp.Vertex[I,1]:=ModelUp.Vertex[I,1]/MinZ;
     ModelUp.Vertex[I,2]:=ModelUp.Vertex[I,2]/MinZ;
    End;
 //Добовление треугольников в массив модели
   Readln(InFile,Str);
   For I:= 0 to Length(ModelUp.Trian)-1 Do
    Begin
     Repeat
      Readln(InFile,Str);
     Until (pos('Face',Str)<>0)or(Eof(InFile));
     Delete(Str,1,Pos('A',Str)+1);
     ModelUp.Trian[I,0]:=StrToInt(Copy(Str,1,Pos(' ',Str)-1));
     Delete(Str,1,Pos('B',Str)+1);
     ModelUp.Trian[I,1]:=StrToInt(Copy(Str,1,Pos(' ',Str)-1));
     Delete(Str,1,Pos('C',Str)+1);
     ModelUp.Trian[I,2]:=StrToInt(Copy(Str,1,Pos(' ',Str)-1));
    End;
   CloseFile(InFile);
  End;

  Procedure PaintModel(ModelUp:Model);
//   Var I:Integer;
   Begin
    GlPushMatrix;
     glTranslatef(0,-ModelUp.Trans,0);
     glRotatef(-90,1,0,0);
     glVertexPointer(3,GL_FLOAT,0,@ModelUp.VertexBuild[0]);
     glNormalPointer(GL_FLOAT,0,@ModelUp.NormalMap[0]);
     glEnableClientState(GL_NORMAL_ARRAY);
     glEnableClientState(GL_VERTEX_ARRAY);
     glDrawArrays(GL_TRIANGLES,0,Length(ModelUp.VertexBuild));
     glDisableClientState(GL_VERTEX_ARRAY);
     glDisableClientState(GL_NORMAL_ARRAY);
    glPopMatrix;
   End;

 Procedure CalcNormals(Var ModelUp:Model);
  Var I,J,Count:Integer; F,S,T:Array[0..2] OF Glfloat;
      Wrki,Vx1,Vy1,Vz1,Vx2,vy2,vz2,nx,ny,nz :Glfloat;
      NormalsVert:Array Of Array[0..2] Of Glfloat;
  Begin
   SetLength(NormalsVert,Length(ModelUp.Trian));
   With ModelUp Do
   For I:=0 To Length(Trian)-1 Do
    Begin
     F[0]:=Vertex[Trian[I,0],0];
     F[1]:=Vertex[Trian[I,0],1];
     F[2]:=Vertex[Trian[I,0],2];
     S[0]:=Vertex[Trian[I,1],0];
     S[1]:=Vertex[Trian[I,1],1];
     S[2]:=Vertex[Trian[I,1],2];
     T[0]:=Vertex[Trian[I,2],0];
     T[1]:=Vertex[Trian[I,2],1];
     T[2]:=Vertex[Trian[I,2],2];
     Vx1:=F[0]-S[0];
     Vy1:=F[1]-S[1];
     Vz1:=F[2]-S[2];
     Vx2:=S[0]-T[0];
     Vy2:=S[1]-T[1];
     Vz2:=S[2]-T[2];
     nx:=vy1 * vz2 - vz1 * vy2;
     ny:=vz1 * vx2 - vx1 * vz2;
     nz:=vx1 * vy2 - vy1 * vx2;
     wrki:= sqrt (sqr(nx) + sqr(ny) + sqr(nz));
     If wrki=0 then wrki:=1;
     NormalsVert[I,0]:=Nx/wrki;
     NormalsVert[I,1]:=Ny/wrki;
     NormalsVert[I,2]:=Nz/wrki;
    End;

   //Сглаживание нормалей
   With ModelUp Do
   For I:=0 To Length(NormalsV)-1 Do
    Begin
     Count:=0;
     NormalsV[I,0]:=0;
     NormalsV[I,1]:=0;
     NormalsV[I,2]:=0;
     For J:=0 To Length(Trian)-1 Do
      IF (I=Trian[J,0])or(I=Trian[J,1])or(I=Trian[J,2]) Then
       Begin
        NormalsV[I,0]:=NormalsV[I,0]+NormalsVert[J,0];
        NormalsV[I,1]:=NormalsV[I,1]+NormalsVert[J,1];
        NormalsV[I,2]:=NormalsV[I,2]+NormalsVert[J,2];
        Inc(Count);
       End;
     NormalsV[I,0]:=NormalsV[I,0]/Count;
     NormalsV[I,1]:=NormalsV[I,1]/Count;
     NormalsV[I,2]:=NormalsV[I,2]/Count;
    End;
   SetLength(NormalsVert,0);
  End;

  Procedure BuildLists(Var ModelUp:Model);
   Var I:Integer;
   Begin
    With ModelUp Do
     Begin
      SetLength(VertexBuild,Length(Trian)*3);
      SetLength(NormalMap,Length(Trian)*3);
      For I:=0 To Length(Trian)-1 Do
       Begin
        VertexBuild[I*3,0]:=Vertex[Trian[I,0],0];
        VertexBuild[I*3,1]:=Vertex[Trian[I,0],1];
        VertexBuild[I*3,2]:=Vertex[Trian[I,0],2];
        VertexBuild[I*3+1,0]:=Vertex[Trian[I,1],0];
        VertexBuild[I*3+1,1]:=Vertex[Trian[I,1],1];
        VertexBuild[I*3+1,2]:=Vertex[Trian[I,1],2];
        VertexBuild[I*3+2,0]:=Vertex[Trian[I,2],0];
        VertexBuild[I*3+2,1]:=Vertex[Trian[I,2],1];
        VertexBuild[I*3+2,2]:=Vertex[Trian[I,2],2];
        NormalMap[I*3,0]:=NormalsV[Trian[I,0],0];
        NormalMap[I*3,1]:=NormalsV[Trian[I,0],1];
        NormalMap[I*3,2]:=NormalsV[Trian[I,0],2];
        NormalMap[I*3+1,0]:=NormalsV[Trian[I,1],0];
        NormalMap[I*3+1,1]:=NormalsV[Trian[I,1],1];
        NormalMap[I*3+1,2]:=NormalsV[Trian[I,1],2];
        NormalMap[I*3+2,0]:=NormalsV[Trian[I,2],0];
        NormalMap[I*3+2,1]:=NormalsV[Trian[I,2],1];
        NormalMap[I*3+2,2]:=NormalsV[Trian[I,2],2];
       End;
     End;
     Setlength(ModelUp.Vertex,0);
     Setlength(ModelUp.NormalsV,0);
   End;
end.
