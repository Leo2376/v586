
test.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <start>:
   0:	b8 01 00 00 00       	mov    $0x1,%eax
   5:	0f 22 c0             	mov    %eax,%cr0
   8:	ea 20 fc 0f 00 00 00 	ljmp   $0x0,$0xffc20
	...

0000000000000020 <boot_spi>:
  20:	b9 80 00 00 00       	mov    $0x80,%ecx
  25:	b8 00 00 00 00       	mov    $0x0,%eax
  2a:	bb 01 20 00 00       	mov    $0x2001,%ebx

000000000000002f <taptap>:
  2f:	89 03                	mov    %eax,(%ebx)
  31:	40                   	inc    %eax
  32:	43                   	inc    %ebx
  33:	43                   	inc    %ebx
  34:	43                   	inc    %ebx
  35:	43                   	inc    %ebx
  36:	49                   	dec    %ecx
  37:	75 f6                	jne    2f <taptap>
  39:	b9 00 01 00 00       	mov    $0x100,%ecx
  3e:	bb 01 20 00 00       	mov    $0x2001,%ebx

0000000000000043 <taptap2>:
  43:	66 89 03             	mov    %ax,(%ebx)
  46:	43                   	inc    %ebx
  47:	43                   	inc    %ebx
  48:	43                   	inc    %ebx
  49:	49                   	dec    %ecx
  4a:	75 f7                	jne    43 <taptap2>
  4c:	b9 00 02 00 00       	mov    $0x200,%ecx
  51:	bb 01 20 00 00       	mov    $0x2001,%ebx

0000000000000056 <taptap3>:
  56:	88 03                	mov    %al,(%ebx)
  58:	43                   	inc    %ebx
  59:	49                   	dec    %ecx
  5a:	75 fa                	jne    56 <taptap3>
  5c:	bc 00 10 00 00       	mov    $0x1000,%esp
  61:	e8 96 01 00 00       	call   1fc <init_uart>
  66:	e8 cd 01 00 00       	call   238 <banner>
  6b:	b0 06                	mov    $0x6,%al
  6d:	ba 00 05 00 00       	mov    $0x500,%edx
  72:	ee                   	out    %al,(%dx)
  73:	b0 02                	mov    $0x2,%al
  75:	ba 00 05 00 00       	mov    $0x500,%edx
  7a:	ee                   	out    %al,(%dx)
  7b:	b3 03                	mov    $0x3,%bl
  7d:	e8 92 00 00 00       	call   114 <send8b_spi>
  82:	b3 3f                	mov    $0x3f,%bl
  84:	e8 8b 00 00 00       	call   114 <send8b_spi>
  89:	b3 ff                	mov    $0xff,%bl
  8b:	e8 84 00 00 00       	call   114 <send8b_spi>
  90:	b3 f0                	mov    $0xf0,%bl
  92:	e8 7d 00 00 00       	call   114 <send8b_spi>
  97:	bf f0 ff 0f 00       	mov    $0xffff0,%edi
  9c:	be 00 80 0c 00       	mov    $0xc8000,%esi
  a1:	e8 47 00 00 00       	call   ed <fill_spi>
  a6:	e8 8d 01 00 00       	call   238 <banner>
  ab:	b0 06                	mov    $0x6,%al
  ad:	ba 00 05 00 00       	mov    $0x500,%edx
  b2:	ee                   	out    %al,(%dx)
  b3:	b0 02                	mov    $0x2,%al
  b5:	ba 00 05 00 00       	mov    $0x500,%edx
  ba:	ee                   	out    %al,(%dx)
  bb:	b3 03                	mov    $0x3,%bl
  bd:	e8 52 00 00 00       	call   114 <send8b_spi>
  c2:	b3 7f                	mov    $0x7f,%bl
  c4:	e8 4b 00 00 00       	call   114 <send8b_spi>
  c9:	b3 ff                	mov    $0xff,%bl
  cb:	e8 44 00 00 00       	call   114 <send8b_spi>
  d0:	b3 f0                	mov    $0xf0,%bl
  d2:	e8 3d 00 00 00       	call   114 <send8b_spi>
  d7:	bf f0 ff 4f 00       	mov    $0x4ffff0,%edi
  dc:	be 00 00 0c 00       	mov    $0xc0000,%esi
  e1:	e8 07 00 00 00       	call   ed <fill_spi>
  e6:	e8 4d 01 00 00       	call   238 <banner>
  eb:	eb 76                	jmp    163 <boot_linux>

00000000000000ed <fill_spi>:
  ed:	e8 5c 00 00 00       	call   14e <recv32b_spi>
  f2:	89 d8                	mov    %ebx,%eax
  f4:	c1 c0 08             	rol    $0x8,%eax
  f7:	88 07                	mov    %al,(%edi)
  f9:	47                   	inc    %edi
  fa:	c1 c0 08             	rol    $0x8,%eax
  fd:	88 07                	mov    %al,(%edi)
  ff:	47                   	inc    %edi
 100:	c1 c0 08             	rol    $0x8,%eax
 103:	88 07                	mov    %al,(%edi)
 105:	47                   	inc    %edi
 106:	c1 c0 08             	rol    $0x8,%eax
 109:	88 07                	mov    %al,(%edi)
 10b:	8a 1f                	mov    (%edi),%bl
 10d:	38 c3                	cmp    %al,%bl
 10f:	47                   	inc    %edi
 110:	4e                   	dec    %esi
 111:	75 da                	jne    ed <fill_spi>
 113:	c3                   	ret    

0000000000000114 <send8b_spi>:
 114:	66 ba 00 05          	mov    $0x500,%dx
 118:	b1 08                	mov    $0x8,%cl
 11a:	d0 c3                	rol    %bl

000000000000011c <nextbit>:
 11c:	88 d8                	mov    %bl,%al
 11e:	24 01                	and    $0x1,%al
 120:	ee                   	out    %al,(%dx)
 121:	0c 02                	or     $0x2,%al
 123:	ee                   	out    %al,(%dx)
 124:	34 02                	xor    $0x2,%al
 126:	ee                   	out    %al,(%dx)
 127:	d0 c3                	rol    %bl
 129:	fe c9                	dec    %cl
 12b:	75 ef                	jne    11c <nextbit>
 12d:	c3                   	ret    
 12e:	b0 06                	mov    $0x6,%al
 130:	ba 00 05 00 00       	mov    $0x500,%edx
 135:	ee                   	out    %al,(%dx)
 136:	b0 02                	mov    $0x2,%al
 138:	ba 00 05 00 00       	mov    $0x500,%edx
 13d:	ee                   	out    %al,(%dx)
 13e:	b3 f0                	mov    $0xf0,%bl
 140:	e8 00 00 00 00       	call   145 <nextbit+0x29>
 145:	b0 06                	mov    $0x6,%al
 147:	ba 00 05 00 00       	mov    $0x500,%edx
 14c:	ee                   	out    %al,(%dx)
 14d:	c3                   	ret    

000000000000014e <recv32b_spi>:
 14e:	66 ba 04 05          	mov    $0x504,%dx
 152:	b0 20                	mov    $0x20,%al
 154:	ee                   	out    %al,(%dx)
 155:	b9 1e 00 00 00       	mov    $0x1e,%ecx

000000000000015a <waitloop>:
 15a:	49                   	dec    %ecx
 15b:	75 fd                	jne    15a <waitloop>
 15d:	ed                   	in     (%dx),%eax
 15e:	ed                   	in     (%dx),%eax
 15f:	ed                   	in     (%dx),%eax
 160:	89 c3                	mov    %eax,%ebx
 162:	c3                   	ret    

0000000000000163 <boot_linux>:
 163:	bc 00 10 00 00       	mov    $0x1000,%esp
 168:	e8 8f 00 00 00       	call   1fc <init_uart>
 16d:	bb 00 ff 0f 00       	mov    $0xfff00,%ebx
 172:	b9 0e 04 00 00       	mov    $0x40e,%ecx
 177:	89 19                	mov    %ebx,(%ecx)
 179:	bf 00 00 09 00       	mov    $0x90000,%edi
 17e:	b9 00 04 00 00       	mov    $0x400,%ecx
 183:	b8 00 00 00 00       	mov    $0x0,%eax
 188:	f3 ab                	rep stos %eax,%es:(%edi)
 18a:	bf 00 08 09 00       	mov    $0x90800,%edi
 18f:	89 3d 28 02 09 00    	mov    %edi,0x90228
 195:	be 20 ff 0f 00       	mov    $0xfff20,%esi
 19a:	b9 00 01 00 00       	mov    $0x100,%ecx
 19f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
 1a1:	b0 01                	mov    $0x1,%al
 1a3:	a3 10 02 09 00       	mov    %eax,0x90210
 1a8:	b8 00 fc 01 00       	mov    $0x1fc00,%eax
 1ad:	a3 e0 01 09 00       	mov    %eax,0x901e0
 1b2:	b8 00 00 50 00       	mov    $0x500000,%eax
 1b7:	a3 18 02 09 00       	mov    %eax,0x90218
 1bc:	b8 00 00 30 00       	mov    $0x300000,%eax
 1c1:	a3 1c 02 09 00       	mov    %eax,0x9021c
 1c6:	b0 50                	mov    $0x50,%al
 1c8:	a2 07 00 09 00       	mov    %al,0x90007
 1cd:	b0 19                	mov    $0x19,%al
 1cf:	a2 0e 00 09 00       	mov    %al,0x9000e
 1d4:	e8 5f 00 00 00       	call   238 <banner>
 1d9:	be 00 00 09 00       	mov    $0x90000,%esi
 1de:	ea 00 00 10 00 10 00 	ljmp   $0x10,$0x100000

00000000000001e5 <sendchar>:
 1e5:	50                   	push   %eax
 1e6:	52                   	push   %edx

00000000000001e7 <wait_rdy>:
 1e7:	ba fd 03 00 00       	mov    $0x3fd,%edx
 1ec:	ec                   	in     (%dx),%al
 1ed:	24 20                	and    $0x20,%al
 1ef:	74 f6                	je     1e7 <wait_rdy>
 1f1:	ba f8 03 00 00       	mov    $0x3f8,%edx
 1f6:	88 d8                	mov    %bl,%al
 1f8:	ee                   	out    %al,(%dx)
 1f9:	5a                   	pop    %edx
 1fa:	58                   	pop    %eax
 1fb:	c3                   	ret    

00000000000001fc <init_uart>:
 1fc:	ba fb 03 00 00       	mov    $0x3fb,%edx
 201:	b0 83                	mov    $0x83,%al
 203:	ee                   	out    %al,(%dx)
 204:	ba f8 03 00 00       	mov    $0x3f8,%edx
 209:	b0 01                	mov    $0x1,%al
 20b:	ee                   	out    %al,(%dx)
 20c:	ba f9 03 00 00       	mov    $0x3f9,%edx
 211:	b0 00                	mov    $0x0,%al
 213:	ee                   	out    %al,(%dx)
 214:	ba fb 03 00 00       	mov    $0x3fb,%edx
 219:	b0 03                	mov    $0x3,%al
 21b:	ee                   	out    %al,(%dx)
 21c:	ba fa 03 00 00       	mov    $0x3fa,%edx
 221:	b0 07                	mov    $0x7,%al
 223:	ee                   	out    %al,(%dx)
 224:	b0 00                	mov    $0x0,%al
 226:	ba f9 03 00 00       	mov    $0x3f9,%edx
 22b:	ee                   	out    %al,(%dx)
 22c:	ba fc 03 00 00       	mov    $0x3fc,%edx
 231:	ee                   	out    %al,(%dx)
 232:	ba f8 03 00 00       	mov    $0x3f8,%edx
 237:	c3                   	ret    

0000000000000238 <banner>:
 238:	be b0 ff 0f 00       	mov    $0xfffb0,%esi

000000000000023d <banner_loop>:
 23d:	8a 1e                	mov    (%esi),%bl
 23f:	b0 00                	mov    $0x0,%al
 241:	38 c3                	cmp    %al,%bl
 243:	74 08                	je     24d <exit_banner>
 245:	46                   	inc    %esi
 246:	e8 9a ff ff ff       	call   1e5 <sendchar>
 24b:	eb f0                	jmp    23d <banner_loop>

000000000000024d <exit_banner>:
 24d:	c3                   	ret    

000000000000024e <final>:
 24e:	eb fe                	jmp    24e <final>
	...
 320:	63 6f 6e             	arpl   %bp,0x6e(%edi)
 323:	73 6f                	jae    394 <final+0x146>
 325:	6c                   	insb   (%dx),%es:(%edi)
 326:	65                   	gs
 327:	3d 74 74 79 53       	cmp    $0x53797474,%eax
 32c:	30 2c 31             	xor    %ch,(%ecx,%esi,1)
 32f:	31 35 32 30 30 6e    	xor    %esi,0x6e303032
 335:	38 20                	cmp    %ah,(%eax)
 337:	72 6f                	jb     3a8 <final+0x15a>
 339:	6f                   	outsl  %ds:(%esi),(%dx)
 33a:	74 3d                	je     379 <final+0x12b>
 33c:	2f                   	das    
 33d:	64                   	fs
 33e:	65                   	gs
 33f:	76 2f                	jbe    370 <final+0x122>
 341:	72 61                	jb     3a4 <final+0x156>
 343:	6d                   	insl   (%dx),%es:(%edi)
 344:	30 20                	xor    %ah,(%eax)
 346:	72 77                	jb     3bf <final+0x171>
	...
 3b0:	62 6f 74             	bound  %ebp,0x74(%edi)
 3b3:	20 00                	and    %al,(%eax)
	...

00000000000003d0 <start2>:
 3d0:	e9 2d fc 00 00       	jmp    10002 <start2+0xfc32>
	...
 3ed:	00 00                	add    %al,(%eax)
 3ef:	00 eb                	add    %ch,%bl
 3f1:	de                   	.byte 0xde
