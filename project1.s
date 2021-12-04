.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb


/* make linker see this */
.global Reset_Handler

/* get these from linker script */
.word _sdata
.word _edata
.word _sbss
.word _ebss




/* define peripheral addresses from RM0444 page 57, Tables 3-4 */
.equ RCC_BASE,         (0x40021000)          // RCC base address
.equ RCC_IOPENR,       (RCC_BASE   + (0x34)) // RCC IOPENR register offset

.equ GPIOA_BASE,       (0x50000000)          // GPIOA base address
.equ GPIOA_MODER,      (GPIOA_BASE + (0x00)) // GPIOA MODER  offset
.equ GPIOA_ODR,        (GPIOA_BASE + (0x14)) // GPIOA ODR    offset
.equ GPIOA_PUPDR,	   (GPIOA_BASE + (0x0C)) // GPIOA PUPDR  offset

.equ GPIOB_BASE,       (0x50000400)          // GPIOB base address
.equ GPIOB_MODER,      (GPIOB_BASE + (0x00)) // GPIOB MODER  offset
.equ GPIOB_ODR,        (GPIOB_BASE + (0x14)) // GPIOB ODR    offset
.equ GPIOB_PUPDR,	   (GPIOB_BASE + (0x0C)) // GPIOB PUPDR  offset
.equ GPIOB_IDR,	   (GPIOB_BASE + (0x10)) // GPIOB IDR    offset


/* vector table, +1 thumb mode */
.section .vectors
vector_table:
	.word _estack             /*     Stack pointer */
	.word Reset_Handler +1    /*     Reset handler */
	.word Default_Handler +1  /*       NMI handler */
	.word Default_Handler +1  /* HardFault handler */
	/* add rest of them here if needed */


/* reset handler */
.section .text
Reset_Handler:
	/* set stack pointer */
	ldr r0, =_estack
	mov sp, r0

	/* initialize data and bss
	 * not necessary for rom only code
	 * */
	bl init_data
	/* call main */
	bl main
	/* trap if returned */
	b .


/* initialize data and bss sections */
.section .text
init_data:

	/* copy rom to ram */
	ldr r0, =_sdata
	ldr r1, =_edata
	ldr r2, =_sidata
	movs r3, #0
	b LoopCopyDataInit

	CopyDataInit:
		ldr r4, [r2, r3]
		str r4, [r0, r3]
		adds r3, r3, #4

	LoopCopyDataInit:
		adds r4, r0, r3
		cmp r4, r1
		bcc CopyDataInit

	/* zero bss */
	ldr r2, =_sbss
	ldr r4, =_ebss
	movs r3, #0
	b LoopFillZerobss

	FillZerobss:
		str  r3, [r2]
		adds r2, r2, #4

	LoopFillZerobss:
		cmp r2, r4
		bcc FillZerobss

	bx lr


/* default handler */
.section .text
Default_Handler:
	b Default_Handler


/* main function */
.section .text

main:

	 push {lr}

	/* enable GPIOB and GPIOA clock, bit0 and bit1 on IOPENR */
	ldr r6, =RCC_IOPENR
	ldr r5, [r6]
	/* movs expects imm8, so this should be fine */
	movs r4, 0x3
	orrs r5, r5, r4
	str r5, [r6]

	/* setup PA pins 0-1-4-5-6-7-11-12*/
	ldr r6, =GPIOA_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x390FF0F //0011_1100_0000_1111_1111_0000_1111
	mvns r4, r4
	ands r5, r5, r4
	ldr r4, =0x1405505 //0001_0100_0000_0101_0101_0000_0101
	orrs r5, r5, r4
	str r5, [r6]

	/* setup PB pins 0-2-4-5-8-9*/
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0xF0F33 //1111_0000_1111_0011_0011
	mvns r4, r4
	ands r5, r5, r4
	ldr r4, =0x50501 //0101_0000_0101_0000_0001
	orrs r5, r5, r4
	str r5, [r6]



		luppo:
		bl idle
		b luppo

		pop {pc}

	 idle:

	bl externalLedOFF

	//idle state:4006
	 movs r7, #4
	 bl firstDigitOpen
	 ldr r1, =#319
	 adds r2,r2,#1
	 bl delay
	 movs r7, #0
	 bl secondDigitOpen
	 ldr r1, =#319
	 bl delay
	 bl thirthDigitOpen
	 ldr r1, =#319
	 bl delay
	 movs r7, #6
	 bl fourthDigitOpen
	 ldr r1, =#319
	 bl delay
	//

	ldr r6, =GPIOB_IDR // to check button if it has been pressed
	ldr r5, [r6]
	ldr r4, =0x104  // for PB2
	ands r5,r5,r4
	cmp r5, r4
	beq driveRandom

	bl luppo

	firstDigitOpen:
	/* turn on led connected to B 4 in ODR */
	ldr r6, =GPIOB_ODR
	ldr r5, [r6]
	ldr r4, =0x330 //0011_0011_0000
	mvns r4,r4
	ands r5, r5, r4
	ldr r4, =0x10  //0001_0000; 0011_0010_0000
	orrs r5, r5, r4
	str r5, [r6]

//compare
	cmp r7, #0
	beq driveZero
	cmp r7, #1
	beq driveOne
	cmp r7, #2
	beq driveTwo
	cmp r7, #3
	beq driveThree
	cmp r7, #4
	beq driveFour
	cmp r7, #5
	beq driveFive
	cmp r7, #6
	beq driveSix
	cmp r7, #7
	beq driveSeven
	cmp r7, #8
	beq driveEight
	cmp r7, #9
	beq driveNine

	secondDigitOpen:
	/* turn on led connected to B 5 in ODR */
	ldr r6, =GPIOB_ODR
	ldr r5, [r6]
	ldr r4, =0x330 //0011_0011_0000
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x20  //0010_0000
	orrs r5, r5, r4
	str r5, [r6]

//compare
	cmp r7, #0
	beq driveZero
	cmp r7, #1
	beq driveOne
	cmp r7, #2
	beq driveTwo
	cmp r7, #3
	beq driveThree
	cmp r7, #4
	beq driveFour
	cmp r7, #5
	beq driveFive
	cmp r7, #6
	beq driveSix
	cmp r7, #7
	beq driveSeven
	cmp r7, #8
	beq driveEight
	cmp r7, #9
	beq driveNine

	thirthDigitOpen:
	/* turn on led connected to B 9 in ODR */
	ldr r6, =GPIOB_ODR
	ldr r5, [r6]
	ldr r4, =0x330 //0011_0011_0000
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x200  //0010_0000_0000
	orrs r5, r5, r4
	str r5, [r6]


//compare
	cmp r7, #0
	beq driveZero
	cmp r7, #1
	beq driveOne
	cmp r7, #2
	beq driveTwo
	cmp r7, #3
	beq driveThree
	cmp r7, #4
	beq driveFour
	cmp r7, #5
	beq driveFive
	cmp r7, #6
	beq driveSix
	cmp r7, #7
	beq driveSeven
	cmp r7, #8
	beq driveEight
	cmp r7, #9
	beq driveNine


	fourthDigitOpen:
	/* turn on led connected to B 8 in ODR */
	ldr r6, =GPIOB_ODR
	ldr r5, [r6]
	ldr r4, =0x330 //0011_0011_0000
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x100 //0001_0000_0000
	orrs r5, r5, r4
	str r5, [r6]

	cmp r7, #0
	beq driveZero
	cmp r7, #1
	beq driveOne
	cmp r7, #2
	beq driveTwo
	cmp r7, #3
	beq driveThree
	cmp r7, #4
	beq driveFour
	cmp r7, #5
	beq driveFive
	cmp r7, #6
	beq driveSix
	cmp r7, #7
	beq driveSeven
	cmp r7, #8
	beq driveEight
	cmp r7, #9
	beq driveNine

	driveNine:
	b numberNine
	driveEight:
	b numberEight
	driveSeven:
	b numberSeven
	driveSix:
	b numberSix
	driveFive:
	b numberFive
	driveFour:
	b numberFour
	driveThree:
	b numberThree
	driveTwo:
	b numberTwo
	driveOne:
	b numberOne
	driveZero:
	b numberZero
	driveRandom:
	b randomNumber
	driveLoop:
	b luppo

//9
	numberNine:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x10F2
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay


//8
	numberEight:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x18F2
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay

//7
	numberSeven:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x32
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay

//6
	numberSix:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x18E2
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay

//5
	numberFive:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x10E2
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay

//4
	numberFour:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0xF0
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay

//3
	numberThree:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x10B2
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay

//2
	numberTwo:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x1892
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay

//1
	numberOne:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x30
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay

//0
	numberZero:

	ldr r6, =GPIOA_ODR
	ldr r5, [r6]
	ldr r4, =0x18F2 //0001_1000_1111_0010
	mvns r4,r4
	ands r5,r5,r4
	ldr r4, =0x1872
	mvns r4, r4
	orrs r5, r5, r4
	str r5, [r6]

	ldr r1,=#319
	b delay


	randomNumber:
	ldr r6, =GPIOB_IDR
	ldr r5, [r6]
	ldr r4, =0x0
	ands r5, r5, r4
	str r5, [r6]
	ldr r5 , =0xFFFFF
	ands r2,r2,r5
	ldr r6, =#8999
	cmp r2,r6
	ble assignment

	randomNumberLoop:
	subs r2,r2,r6
	cmp r2, r6
	ble assignment
	b randomNumberLoop


	assignment:
	ldr r4, =#1000
	adds r2,r2,r4
	movs r0,r2


	assignmentLoop:
	subs r0, r0, #1
	ldr r7, =0x0
	ldr r1, =0x0
	ldr r5, =0x0
	ldr r6, =0x0

	firstDigit:
		ldr r7, =0x0
		movs r2, r0
		ldr r3, =#1000
		cmp r2, r3
		ble firstDigitLedON
	firstDigitLoop:
		subs r2, r2, r3
		adds r7, #1
		cmp r2, r3
		bgt firstDigitLoop
	firstDigitLedON:
		bl firstDigitOpen
		ldr r1, =#318
		bl delay

	secondDigit:
		ldr r1, =0x0
		ldr r3, =#100
		cmp r2, r3
		ble secondDigitLedON
	secondDigitLoop:
		subs r2, r2, r3
		adds r1, #1
		cmp r2, r3
		bgt secondDigitLoop
	secondDigitLedON:
		movs r7, r1
		bl secondDigitOpen
		ldr r1, =#318
		bl delay

	thirdDigit:
		ldr r5, =0x0
		ldr r3, =#10
		cmp r2, r3
		ble thirdDigitLedON
	thirdDigitLoop:
		subs r2, r2, r3
		adds r5, #1
		cmp r2, r3
		bgt thirdDigitLoop
	thirdDigitLedON:
		movs r7, r5
		bl thirthDigitOpen
		ldr r1, =#318
		bl delay

	fourthDigit:
		ldr r6, =0x0
		movs r6, r2

		movs r7, r6
		bl fourthDigitOpen
		ldr r1, =#318
		bl delay

		ldr r1, =#3185
		cmp r0, #0
		beq zeroWait

		b assignmentLoop

	delay:
		subs r1, r1, #1
		bne delay
		bx lr

	zeroWait:

		//externalLedON
		ldr r6, = GPIOB_ODR
		ldr r5, [r6]
		ldr r4, =0x1
		orrs r5, r5, r4
		str r5, [r6]

		//for 0000 
		push {r1}
		bl firstDigitOpen
		bl secondDigitOpen
		bl thirthDigitOpen
		bl fourthDigitOpen
		pop {r1}

		subs r1, r1, #1
		bne zeroWait
		b driveLoop

		externalLedOFF:
		ldr r6, =GPIOB_ODR
		ldr r5, [r6]
		ldr r4, =0x0 // for PB0
		ands r5,r5,r4
		str r5, [r6]
		bx lr




	/* for(;;); */
	b .

	/* this should never get executed */
	nop
