� �COM File to EXE File Conversion Utility (04/01/85)
 �YCopyright (C) 1985 SOFT WAREHOUSE, Inc.

 �>]  t�H�!To use this utility, you must include the name of the COM file
in the COMTOEXE command.  The destination drive is an optional
second argument.  For example, to generate the file EXPERT.EXE
on drive B: from the file EXPERT.COM, enter the MS-DOS command:

      COMTOEXE EXPERT B:

Please try again; returning to DOS
 ���l ���>e  u�e C�f O�g M�\ ��!<�u-�COM file not found; returning to DOS
 �q�l �n ��� ������������������������������������@��j  �}   �   �] ���_ ���a ���c ������!<�u.�Disk directory full; returning to DOS
 �� �� ��  ��  ���!� ���(�!��u� ��!� �\ �'�!�X���(�!��t����!����!� Insufficient disk space for EXE file; returning to DOS
 �G ����!�T Conversion complete; EXE file saved; returning to DOS
 � � ��< ��L�!� ��/ �
�* ��[P�
 XS���� �C"�u��� t��R����!Z�PR�д�!ZX�           EXE                                                  MZ          ���    ��                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        