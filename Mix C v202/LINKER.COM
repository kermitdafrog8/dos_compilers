��1 %������؉%.� �1��+±���u������%���'�ڎҋ���@��£3�0��)3�3��� �ڎȎ���ڰ �+�G�ȉER�؉EV�+�EB�,�EA�EJ'�؎����m�5 �L�+	�5 �`	���! �'- �8��3�������K @%���!	��-K�<�#K�'- �8��+��,���.�6'�,H�'���'���� � �E����u� ��)�*r�5�E �'�~$3��@�:�E���G��t�n� �#� �I$�7�P��g$�7C�2��IC�C<a|<z, <Lt;<Bt@<Rt?<ItJ<QtO<EtK<TtG<St.<Ct9<Ht8<FtK<Ot6<At:<Xt9<Mt8�j����� �l������� �]�� �������6����������@ �<At<at	�� �$���IC���
>>
H=Help,     L=Load,     F=Find,     FA=Find All
S=Symbols,  R=Run,      B=Build     C =Change runtime
I=Init,     E=Exit,     O=Overlay   OA=Overlay Area �!	�'+�-� +<�2 ����"� Bytes left �'�!	C� C����+���  �CC��ËȻ7�< � ��"�7C� �h"�FILE    ~                               *                                              ��r��t�.�."���x �K��'	�L�6%	�6N���#	���)	�!	<�!	�P����u���	��+><G� ��P� P��PWP�؎��Ȏ���	� �!	+<��	�Ȏ���˻�!�)�** Unresolved references Use Build command with overlays ����2����G���G�� ��؎���ȵ ��GG2��"�I< t����I<[u� ��<t	���:6�r�� ���u�W������I< t�� ���I<]t<t	���:&�r뿇�� _�� u2�?�J���� �!r�8��+ыJ�?�!r� $ �� �D��'� ��� ��G�������Runtime support file missing Error reading runtime file �L� �=�!�Js6���؎������t#���t���V�L����u�� �=���!�J^s����:�ô>�J�!��E�u��� ��� �����P���!	C����X��u�  �ȋ6#�
Stack size: �E�u2�/�) ��7����7�G�t�G<Nt<nt<Yt<yu˰�2��Include runtime support in command file? �7�P�w�7�9���s����t�L�J��!	�\�%��'	�L�6%	�6N���#	���)	�!	<�!	�P�>�P�N�#�  �؎�P�Ȏ���~�� �W�� ��#�� ��X�ػN�G�8�G��E�u��	����P����7G��F�� FG� �؎���<,t)<.u�E�u�	�<,t	< v������ �< v����Ҿ
� .�������7�� �7�N�w���N�	���7�G�t�$�s���  X��u� ���u_��� 3ɋJ�B� �!rI�!	+<����������� �!	+<B�,- +��!	+<BQ;�v�΋J�?�!Ys� PQ�ȋ!	+<B�N�}�]��@�!Yr;�uXrw+�u��x��K�X�h�	�!	+<+�Q���v���N�}�]��@R�!Zr�;�u�Yr9�+�uؿN�}�]�S�@3��![r �>�!r�	�D�t�y ��	� �13��P��	� �X�zR��	�	[������� ���c** Error building file ** *** Can't create:  - done - File    =  .COM �7G��F�� FG� �؎���<,t<.t	< v����
� .������� ��7����<�!r>P�,�.��� +��"[SQ� R�@�!Zr��R� �@�!ZrY����[�>�!r�Y[��
�)�Error building symbols file .SYM �C��7�P���7C���t6�� <a|<z�!.��t�.:t����.�_�����7����6�Press return to continue L�FRE=IqB�CSzO�AqX 
Help is available for the following commands:

   L = Load an object file
   F = Find modules in a library
   R = Run the program
   S = Display symbols
   I = Initialize
   B = Build command file
   C = Change runtime file
   O = Start overlay
   A = Start overlay area
   X = Set extra links
Use the return or enter key to exit from help

<Help>  The load command loads one or more files containing
object code into memory and links the modules together.
 The find command searches a library and loads only
the modules that have been called by some previously
loaded module.   Find all will search a list of
libraries repeatedly until all modules contained in
them that are needed have been loaded
 The run command executes the program.
 The exit command returns to the operating system.
 The initialize command removes all code that has been
loaded and restores the loader to its initial state.
 The build command creates a command file on disk.
The runtime support routines may be included in this
file to create a completely self-contained command 
file.  If the runtime support routines are not included
in the command file, they will be loaded by the program
when it is executed.
 This command allows you to change the name of the file
that is expected to contain the runtime support routines.
 The symbols command displays the names of defined
and referenced symbols.
 The O command begins an overlay in the current overlay
area.  The name of the overlay file is set and the overlay
loader is loaded when the first overlay is started.
 The A command begins a new overlay area.  All overlays in
a given area occupy the same memory.  At run time, one
overlay can be present in each area.
 The X command sets the number of extra links between
overlays.  Each function that is called from a different
overlay than the one in which it resides requires one link
unless it is also called from outside any overlay.
 ���%�D���u���! ��7����7C�2�C�p�< t<,uCI���Ӵ �C< t<,t����ڃ����g�û��m���w���m���E�؎����m�5 �L�+	�5 �'- �8�O��1���File containing runtime support: ����uSQ��Y[t�}�Q��Y��u)�E���7���7�O2����u�@�t�bË��@�t	QV�W^Ysn������؎��a�< t
<,t<tT����N� ��<.u����< t<,t<t<.u�ƪ����AIVQ��u�P� .������� ����g�)Y^r��u�ú���� ��s,�@������3ɬ���tA�����O�.PS��[Xr��Q�Ys�����t�Q��Y��u7�E���7���7�O2���@��u�.P�c �dXs;.u�á.PSQ�QYQs��Y[X;.u��Y[X�R�0�[����� �]��*** File not found:  File(s) =  .MIX�	�0����x[u����VS���r��rD����t5�7��3ɬ��t�A��[S��C�A��u��7�O��V���r�^s	��[^���[^û���y�����������Not implemented �\�������** Address conflict** IO Error��c��uk�G�uv�6
<:ua�\��t@P�T��R�NZ��R�GZ��tX�@ +<;�sS��� �{[X���Y2����G����	<
t����u��G� u����S��� �C[�|S��� ��S�.!	�N�#�  .��FG���~�� �W�� .��#�� .��FG���N�8�GX�w�`� �a�G�u/�s)��3��;�D�,�B�.�>�i
��u�B	<:t�������T
��t����	<Aty� �:��.:��uI.�dX�W�FEP�E�GZI�J�KM@N�Q�:EYK\DRZB�CL\S��� �>[�w*** INVALID OBJECT���G�l���@�t:�D�u�.!	�B�,�>�.�S�S�F�< t� ���F� � C��[��.!	������.� �6,��	 +����3��,�B�.�>�@�t�D�t�'r��3��D�;�t���������"�<�#���P�B�[��Z�<�D<t!<tL�@�uHS��� �'�0� �[�/�DS�\��t������\��t���+�+<HH�����[�T�D �I�S�P������X�D	�| t�D[�*��S�0� �@�t�F��CF����[��S�Z�����| t�D��|GG[����׋D+�+<HH���S�,P�(P�W�p���D<t<tXX��� �I�0� �2[��XX�D	���DX�DX�D	�D  ��** DUPLICATE SYMBOL: S�� ����D<t/��� � ��Ћ��S�S� �L���D< t�D��|GG[�5��D�GG[�*�� �<�GG���p �GG���"� �c���;���2���P�W ��2����
Q��FY��� S�����MZY��t����E������� $2�S�	��[��� P� Z����;� t���� ��������P� $Z
���]�þ0� Q�OY�F���;>!	r�>!	�W�.�>,����0Q� �؎���Yu�4�� ��I��,- �,���о0� �؎����G� � G���.��_ò �.�(�6,;D	u�|t�|t��u	���t��Á� �ܻX� �z�,ò��
*** ILLEGAL REFERENCE ***W�6,�.�3�D<u&�D�D�!	£!	�|<�T��t�������I��_ú  �n �,��.��� +��DQ� ��< C���> �D��u�D�
��u�R��C� �# �DP���! X� �! �� ��YI��QR�N	ZY�QR�|	��QR�G	��QR�c	ZB�� |�  RS�P� �n
�7��
[ZR��**MORE**�6,�.��|t�� ������S�6,�.����9�T	�D<u*V���;!	r�؋���^V���;!	r�؋���^����[�SQRVW�w���e
_^ZY[DD��!��x�mT�
�mT��mT��mTV�w��S�  � C���ڹ �  �������t0[�w�؎���� +�2��2��� � ���2�.��#�� �����^�[^�VP�w�G�t�� �G �� ��
 Ƅ�� �G�ȴ��G�t3��G�g�G �r�@t�G�X3�P�5 ��XP�G�t�t�$�=�T��&�sZR��ti�<�T�3ɊL���rZ�D��G �GX�tF3�3Ұ�B�GS�\�u���[�D����D����$IJ����?� Q�����Xr<u����Ѱ�B��[^ð��G�G X��L��Àr�@u@�G�t:V�w�G�u5�G�t�Gt����@3�S�\��i�[�>S�\��_�[s�G^�G ����V�w�G<rP<t< tH�G�� �,�w
��S���-[�Gu��F� �F�w
���D
�~ +�)G
�G�G�ȈG� �G�u��G�G:Gt�G
� �G � �G�G
�G �G� �����Q�?S�W
�\���[Ys�i ��u�G�[�D�;�u��� ���@��VW�����H��N�ʌ؎����_^�¹ ��O�Ɋ�*ȋ�% ��� =� |3����G�O� �P� ^ÈG��V�w�D�tQRP�yXZY�<u�D�t	QRP�XZYS�\��B��[�ʋ�s�G�G�ȈG�G� �G �D� ^�V�w�G S�\��?���[r;�t
�G�G���^ÈG3���V�w� S�\��@��[r;�t�G���^ÈG���D�tRQ�D�t����&YZ�D� �V�w�G�t�D�t��G��G�G�
�G�t�^ÊG< }	�s����G�w
2����G�G�w�D�^ÊG<t<@t#< t<u�����*tĴ�*t����д?S�W
�\�� ���[r�� u�w
������G�G�w��O�<u�G<u�G � <
u�5��<	u�g��t�O� ��G�u�G�u�_ <t��<u��Q <
u����G ��G���G�t4�G �t.�G�u(�G�u"�$ �G�u�Gu�r
�@t<t2�ð���V� }0�r'���G�x�O�"�W�ʈW�w����w
�G�"�% �G�u�w
�G2���<	u	�G��u� ^ð��� }����G�G:Gt
�G
� �G �� ËG�G
V�w�D�t(�G� ����O��� ���@�W
S�\���[r;�u� � �G�G �G �D� ^ËȰ���G�G
V�w�G�G�t���W:�}/� ��� ��O��� �+���B��3Ʌ�yI�S�\���[r�G �G �D� ^ÈG��G�G
ÁG
� ËG�� ���G
��G�t�G�uV�w�D�^tP�l�X���G�G<rO<th<t<t<t<@t< t����M������@S�W
�_�O��ڈ�ٹ ��[r= uÈ� �V�w
2�G���w�D��Gy��^ð�f��
�a��G �% �� �t�Q VS�w�\��B�3ɋ��'�r2[SRP�\��B�3ɋ���r$Y^[SRP�ы΋w�\��B� ���rZY[^�[^�G�ZY��VS�w�B��\��B�3ɋ����[r�ʋ�^ÈG^�S� �x�8$� ��7�P�G ��d[�7V�w� ^� = WVS@�؊� C�o�< uC���d<:u�� ��t_�G<:td�G<:u�^%�� t_�a%�� tW����}�:u
I��[�G@���[���ڎ��}���u�G���< t���� �^_�[�G��� �G<:t볺 ��r��� ��r��<ar�<At><Lt6<Pt2<Nt*<Dt&<It<Ot<Eu�� [�G �w�D�렸  �� ��������[�Gʋ�뀺 ��t�G��s�SQ� �C<a|�:uG��:�Y[�LSTDMY����e��P��������0<9~���X$0<9~���ð����
���ð ����V3ҋʋ���F��j��F�< uIu��[ �<>tY<#tU<+t<-u��FI�C�<Kt&<kt"< tP�
 ���X,0x<	��ހ��u���P� ���X����R�y&� � Z��^�FI���� �������������<0|<9~!<A|<F~<a|<f~SQ�d&� �u �  Y[�,0�����*** Invalid HEX digit*** Invalid digit��C�����ÊC��t���������������������	.�C�����.�C��t�����������������2��
������WV����t��  }���-�� G�?'���.��/��+�s��FF��0t�-G� ��0�^_À���-t���� u� ��ƅ�� �-��'�d 
 VW��  � P������@�< t�<+t<-u����� s��u��t���t�G����u� ��t&xz��� s��t���u	��u����G����t^��uV�� <+t<-u���� s�� ru9��$��̀����������x���t�� u�Āt���q��� _^�ð����� ��V������GF��u�^F��� � GF��NLZ��[��Y��Z���r��$���$r� �$��^�� V�_^Á� ��<0r"<9v<Et<Dt<et<dt	�����,0�Ä�� Ä�t< t	<.u�������� u��u�Ŵ-�u�� �x�+�u� �%�t	WP�lX_��� ����Qv����WP��X_�ר�t
�%��+u� �t"�-�� �x�+�u� �%G��u�OP����X���t,�%��+t��-uG�ϊ%G�� t�O;�u�Ȱ$����ƅ��$���%��+t��-u�� �� u� G�%���� t�%�� u�*G����t,�G<.u��ϊ<0r<9wG��O�<0u�PO��<.u�D�VPSQR�� ��x�+t8��-� W�����������0�OO��_��W��� �$0�OO��_��^�WG� �00��������EG�+$t,@y�-�؈%G�/��,
s��%G:�GÀ�s	�%�� t����GVW��QW������Z�_Y�� �F��t!��t�����0��u	��t� ��ΈG��u��.G��t��t�����0�G��u���h�� ��_^è@t���~������Ws	�%�� t����GV��PQRW������ �#���_ZYX�� ��t��@y� :�tAw�� �%�� t4G�1��*��u��t!�@t� ��:�:�~������ G��u���u�0G� ��t��@y�y*� F��@t���ts������t!��t�����0�G��u��t�,G���u��.G��x
t�0G��u���t��t�����0�G��u�� ��^_�P�� $t,@��y� ���y�y� Xù  ��W�G��u��_�W���t	�� �G��_Ê� ��t$�����<s����� $��P�  �ˋ����|��x���� �u��Ä�u�è�u����� �u�&�� ��WU��
 ��� s��È� � 3��i �� u�� q��
 ]_��Ç��� �����������> �ňO� ���2 ����u�G�� ��� �� �� �� X���s	�k�݊��]_�����E�� �� /��s�� �� '��MU�� ������������]���S�� ��2�䀁�*�q[�À�Ax���[��� �u�Ä�u�5��P�� %*�sX�#���vX���aX�� 2� y�C �� s� �g� �� �e VP���'�Ь�'���'�Ȭ�'���'�ج�'��X'^�VP��*/��F��/��F��/��F��/��F��/��F��/��FX/^�s��t���tUP��O ]����]�ð��UP�� *�/�а �/�� �/�Ȱ �/�� �/�ذ �/��� �/]�݊��]��Ä�tf��tbW����t��ȋӵ 3۰ �� t��ыˊط � �� t��֊�͊�ߊ�� �� t��� �������������_�����Pr� Ê� 3�3�3����� �� �� �x���� �� �� Ä�t>UP� ��u���Ǌ��݊�Ί� ��r�X]3��è�u��� ]�����2��ǀ��]u�ð��U�� ������������]Ê��'��s+� �'��s"� �'�Ȱ �'�� �'�ذ �'��� �'Ê�Ç�� �� �� ��� �u����� �t��� s���PU��� �� �� � PSQR��� � � �� � U�-�T �-���������G G]Mu��  ���� ��u�� �������������P��2��uX]�İs�'��%_���X]���W� �����t�T���� '���� ���� u�� ��  _��3���� '��^PSQRV��FF�U�� ������������u���]�S�� �� ��2�䀁���@�x��[����3��؋ȋ�Ä�u�� �u2�Ê� �ؘ������ �u����:� t'�Āu�� �t��:� w������ �t�:� v�����r��u��u��u��t��� �t������ �t�뽄�t7�Ű�  �  s,�а�'�ذ �'��� �'�Ї�s� ��������q���Ä�t�������������������������������������������������������������������                                                                                                                                                                                                                                                                                               &�N �"n!� A,d%   '                        N                                                                           Q                                                                                                                                                                                                                                       P                                                                                                                                                                                                                                                                                                  MAPFILE ��           �                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       G'�(                                                                                            RUNTIME }�        �              L          RUNTIME OVY                           RUNTIME.OVY                                                                                                                                                                                                                         Dd���          CLIB.MIX                        PLIB.MIX                                         BLIB.MIX                                                        LINKER.MIX                      A: A:\                                  ��`                                                                                                �Ȏؾ ��
  ������� �� +ǋ� �� ��Ȍ�Ӿ,�� ��NO��  ����; sA�¿  ������O �Ҽ� �� �� �� �� ��
 �ڌ�P��P3�P˺�	�!�L�!Not enough memory
$�Ȏ�X����=� �!sAV�H��t+�b�C��t�G����F�G��u�S�b�=� �![s��^�� �	�!�L�!^��P�A�� �?�![s
=� t�� �ݾAX;� uX;� t������S�T� 3ɴB� �![rό�P�t �L������L� +�S�׌�P����Q�?�!YZ��[r�;�u�� �>�!�Missing runtime file
$ Error reading runtime
$Wrong runtime
$                                                                                                                                                                                                                                      