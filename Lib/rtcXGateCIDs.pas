unit rtcXGateCIDs;

interface

const
  cid_BASE = 65000;

  cid_GroupAccept = cid_BASE + 1;
  cid_GroupClosed = cid_BASE + 2;
  cid_GroupAllowControl = cid_BASE + 3;
  cid_GroupDisallowControl = cid_BASE + 4;
  cid_GroupConfirmSend = cid_BASE + 5;
  cid_GroupConfirmRecv = cid_BASE + 6;

  cid_ControlMouseDown = cid_BASE + 11;
  cid_ControlMouseMove = cid_BASE + 12;
  cid_ControlMouseUp = cid_BASE + 13;
  cid_ControlMouseWheel = cid_BASE + 14;
  cid_ControlKeyDown = cid_BASE + 15;
  cid_ControlKeyUp = cid_BASE + 16;

  cid_ImageInvite = cid_BASE + 21;
  cid_ImageStart = cid_BASE + 22;
  cid_ImageMouse = cid_BASE + 23;
  cid_ImageData = cid_BASE + 24;

implementation

end.
 