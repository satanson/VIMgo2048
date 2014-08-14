"a little funny game called go2048(http://go2048.com/), but this implemented in VIM script programming and some perl codes.
"*******************************************
"author: satanson
"email: ranpanf@gmail.com
"date: Thu Aug 14 21:37:54 CST 2014
"*******************************************
"HOW TO PLAY
"1. open go2048.vim in VIM editor.
"2. execute command ":so %"
"3. play the game,OPERATING keys as fellows:
"	<F2> -- Reset game
"	<F3> -- Quit  game
"	<Up> -- Move up
"	<Down> -- Move down
"	<Left> -- Move Left
"	<Right> -- Move Right

func! s:str(n,char)
	return join(map(range(1,a:n,1),"a:char"),"")
endf

func! s:drawVruler(w,n)
	return join(map(range(0,a:n,1),"'|'"),s:str(a:w," "))
endf

func! s:drawBoard(cellw,cellh,celln)
	let s:old_tabnr=tabpagenr()
	echo "s:old_tabnr=" s:old_tabnr
	if !exists("s:go2048_tabnr")
		tabnew
		sil! file go2048
		let s:go2048_tabnr=tabpagenr()
		exe "tabn ".s:go2048_tabnr
		exe "tabclose".s:old_tabnr
	endif

	let linenum=1
	let maxlinenum=(a:cellh+1)*a:celln+1
	while linenum<=maxlinenum 
		if (linenum-1)%(a:cellh+1)==0
			call setline(linenum,s:str((a:cellw+1)*a:celln+1,"-"))
		else
			call setline(linenum,s:drawVruler(a:cellw,a:celln))
		endif
		let linenum+=1
	endwhile
endf

func! s:renderRow(row,cellw,celln)
	let [lbar,rbar]=[1,1+a:cellw+1]
	let s="|"
	for i in range(0,a:celln-1,1)

		let var=""
		if a:row[i]
			let var.=a:row[i]
		endif

		let width=len(var)
		let padding=a:cellw-width
		let [lpadding,rpadding]=[padding/2,padding-padding/2]
		let s.=s:str(lpadding," ").var.s:str(rpadding," ")."|"
	endfor
	return s
endf

func! s:drawMatrix(matrix,cellw,cellh,celln)
	for i in range(0,a:celln-1,1)
		let linenum=((a:cellh+1)*(2*i+1)+2)/2
		call setline(linenum,s:renderRow(a:matrix[i],a:cellw,a:celln))
	endfor
endf

func! s:perlInit()
	perl<<DONE
	sub sample {
		my ($b,$e,$n,$d)=@_;
		my (%samp,@samp);
		while(@samp<$n){
			$r=$b+int(rand($e-$b));
			if ($d || !exists $samp{$r}){
				$samp{$r}=1;
				push @samp,$r;
			}
		}
		return @samp;
	}

	sub squeeze {
		my ($k,$i,$ok)=(0,1,0);
		my @array=@_;
		while ($i<@array){
			if ($array[$i]!=0) {
				if ($i!=$k && $array[$i] == $array[$k]) {
					$array[$k]+=$array[$i];
					++$k;
					$array[$i]=0;
					$ok=1;
				}elsif ($array[$k]==0) {
					$array[$k]=$array[$i];
					$array[$i]=0;
					$ok=1;
				}elsif ($k+1!=$i) {
					++$k;
					$array[$k]=$array[$i];
					$array[$i]=0;
					$ok=1;
				} else {
					++$k;
				}
			}
		}continue{++$i}
		return ($ok,\@array);
	}

	sub shiftMatrix {
		my ($dir,$n,$mat)=@_;
		my $squeezed=0;
		foreach my $i (1..$n){
			my @i=();
			if ($dir eq "left"){
				@i=map {($i-1)*$n+$_-1} 1..$n;
			}elsif($dir eq "right"){
				@i=map {($i-1)*$n+($n-$_)} 1..$n;
			}elsif($dir eq "top"){
				@i=map {($_-1)*$n+$i-1} 1..$n;
			}elsif($dir eq "bottom"){
				@i=map {($n-$_)*$n+$i-1} 1..$n;
			}
			my ($ok,$array)=squeeze(@{$mat}[@i]);
			if ($ok){
				$squeezed=1;
				@{$mat}[@i]=@$array;
			}
		}
		my @rest=();
		foreach (0..$#{$mat}){push @rest,$_ if $mat->[$_]==0}

		return 0 if !$squeezed && !@rest;
		if ($squeezed && @rest){
			$mat->[$rest[((sample(0,@rest,1,1))[0])]]=((2,2,2,4)[((sample(0,4,1,1))[0])]);
		}
		return 1;
	}
DONE

endf


call s:perlInit()

func! s:sample(b,e,n,d)
	let [@b,@e,@n,@d]=[a:b,a:e,a:n,a:d]
	perl<<DONE
	($b,$e,$n,$d)=map{(VIM::Eval('@'.$_))[1]} qw(b e n d);
	@samp=sample($b,$e,$n,$d);
	VIM::SetOption("statusline:".join(",",@samp));
DONE
	let samp=split(&statusline,",")
	set statusline&
	return samp
endf

func! s:xy(n,celln)
	return [a:n/a:celln,a:n%a:celln]
endf

func! s:n(x,y,celln)
	return a:x*a:celln+a:y
endf

func! s:new2_4()
	return [2,2,2,4][s:sample(0,4,1,1)[0]]
endf

func! s:initMatrix(celln)
	let row=map(range(1,a:celln,1),0)
	let matrix=[]
	for r in range(1,a:celln,1)
		call add(matrix,deepcopy(row))
	endfor
	
	let pos=s:sample(0,a:celln*a:celln,2,0)
	for p in pos
		let [x,y]=s:xy(p,a:celln)
		let matrix[x][y]=s:new2_4()
	endfor
	return matrix
endf

func! s:flat(matrix)
	let array=[]
	for row in a:matrix
		call extend(array,row)
	endfor
	return join(array,",")
endf

func! s:deflat(csv,n)
	let array=split(a:csv,",")
	let matrix=[]
	for i in range(1,a:n,1)
		call add(matrix,array[(i-1)*a:n : i*a:n-1])
	endfor
	return matrix
endf

func! s:shiftMatrix(dir,n,matrix)

	let m=s:flat(a:matrix)
	let [@d,@n,@m]=[a:dir,a:n,m]

	perl<<DONE
	my ($d,$n,$m)=map{((VIM::Eval('@'.$_))[1])} qw(d n m);
	my @m=split /,/,$m;

	if (shiftMatrix($d,$n,\@m)){
		VIM::SetOption("statusline:".join(",",@m));
	}else {
		VIM::SetOption("statusline:GameOver");
	}
DONE
	
let rc=&statusline
	set statusline&
	if rc=="GameOver"
		return []
	else
		return s:deflat(rc,a:n)
	endif
endf

func! s:printMatrix(matrix)
	echo s:str(10,'*')
	for row in a:matrix
		echo row
	endfor
	echo s:str(10,'*')
endf

mapclear
mapclear!
imapclear
omapclear
nmapclear
vmapclear
cmapclear
smapclear
xmapclear
lmapclear


command!  -nargs=0 Reset call s:reset()
command!  -nargs=0 Quit call s:quit()
command!  -nargs=1 Shift call s:shift(<f-args>)

nmap <Up> :Shift top<CR><Esc>
nmap <Down> :Shift bottom<CR><Esc>
nmap <Left> :Shift left<CR><Esc>
nmap <Right> :Shift right<CR><Esc>
nmap <F2> :Reset<CR><Esc>
nmap <F3> :Quit<CR><Esc>

let [s:cellw,s:cellh,s:celln]=[10,5,4]
let s:mat=s:initMatrix(s:celln)
func! s:reset()
	set statusline&
	let s:mat=s:initMatrix(s:celln)
	call s:drawBoard(s:cellw,s:cellh,s:celln)
	call s:drawMatrix(s:mat,s:cellw,s:cellh,s:celln)
endf
func! s:quit()
	exe "quit!"
endf
func! s:shift(dir)
	if !empty(s:mat)
		let s:mat=s:shiftMatrix(a:dir,s:celln,s:mat)
	endif

	if empty(s:mat)
		let &statusline="Game Over, Play Again? (<F2>:reset,<F3>:quit"
	else
		call s:drawMatrix(s:mat,s:cellw,s:cellh,s:celln)
	endif
endf

call s:reset()
