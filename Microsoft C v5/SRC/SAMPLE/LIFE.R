 <
 x< ***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<*****  x
 x�* x                           Welcome to                             x�* x
 x<* x                                                                  x<* x
 x�* x   ����                �          �     �                         x�* x
 x<* x  �    �               �          �     �   x�* x                      x<* x
 x�* x  �        ����    �����   ����   �     �  �    ����   �     �    x�* x
 x<* x  �       �    �  �    �  ������   �   �   �   ������  �  �  �    x<* x
 x�* x  �    �  �    �  �    �  �    �    � �    �   �    �  � � � �    x�* x
 x<* x   ����    ����    ����    ����      �     �    ����    �   �     x<* x
 x�* x                                                                  x�* x
 x< ***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<*****  x
 y y y y y y










 y

 x * x You can use function keys to execute code a step at a
 x * x time. Watch the action in source mode . . . y y y y y y 
 B y B y B y B y B y
 x * x . . . or in assembly mode. y y y y y = D y D y D y D y D y                                                                             s+






 x * x With CodeView, you can use either menus or
 x * x dialog commands.

 x * x Menus provide an easy way to execute most commands. y y y y y ! y M y M y M y M y M y M y M y M y y y y K y K y K y K y K y K y K y K y







 x * x For example, you can find source-code text . . .
 y y y y y  y y
incr = (COLS + 1) y y y
 x * x . . . then execute to that location.
 
 y y y y y A y
 




 x * x You can open a window at the top of the screen
 x * x to watch program variables . . .
 y y y y y P  y
i y y y y
 P x * x . . . then set a conditional breakpoint . . .
 y y y y y y P  y P y
i == 5 y y y y
 P x * x . . .and execute until the condition is true.
 y y y y y y  y P y P y y y




 x * x Menu commands involve a selection made from a
 x * x particular menu. With dialog commands you simply
 x * x type in a command, along with any arguments you want.
 y y y y y y y

 x * x For example, the following dialog command deletes
 x * x watch statements. The "*" argument says delete all
 x * x statements in the watch window . . .

 xY * x y y y y y y y





 x * x CodeView dialog command enable you to deal with memory directly.
 x * x You can modify code or data and examine memory in different
 x * x formats. For example, here are bytes, displayed in
 x * x hexadecimal:
 y y y y y y y y y y

 xDB mat1 L 48 x
 y y y y y y y y y y




 x * x When you are several levels deep in your program, you can use
 x * x the Calls menu to examine called functions and their arguments.
 y y y y y y y y . y y y y






 x * x When you execute code, the program action occurs on a separate
 x * x screen. This makes it easy to debug graphics programs.
 x * x Watch the graphics output of the current program, LIFE.
                                                                                   of+
 xG x y y y y y









 x * x You can restart your program at any time, retaining any
 x * x existing watch statements or breakpoints.
 y y y y y y y y y  y P y y y






 x * x Once started, you can execute your whole program or just
 x * x execute up to a specific line of source code.
 xG .55 x y y y y






 x * x You can use C expressions to change the values of
 x * x key variables.

 x? cell='*' x y y y y y

 x? attrib= 13 x y y y y y

 x? density=11.7 x y y y y y y





 x * x Then when you run your program, its behavior will be
 x * x changed.

 xG x y y y y y






 x * x If you get stuck, the on-line help provides quick
 x * x reference to CodeView commands.


 # y y y y P y P y P y P
:::N:::N:::P:::P:::C






 x * x That ends our demonstration. To learn more about using
 x * x the CodeView debugger, try the other menu selections.
 y y y y y y y y y
 x< ***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<*****  x
 x�* x                                                                  x�* x
 x<* x                                                                  x<* x
 x�* x   ����                �          �     �                         x�* x
 x<* x  �    �               �          �     �   x�* x                      x<* x
 x�* x  �        ����    �����   ����   �     �  �    ����   �     �    x�* x
 x<* x  �       �    �  �    �  ������   �   �   �   ������  �  �  �    x<* x
 x�* x  �    �  �    �  �    �  �    �    � �    �   �    �  � � � �    x�* x
 x<* x   ����    ����    ����    ����      �     �    ����    �   �     x<* x
 x�* x                                                                  x�* x
 x< ***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<***** x�* x<*****  x
 y y y y ! y P y P y

