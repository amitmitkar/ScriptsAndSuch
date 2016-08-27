#!/bin/bash
# Usage : xhotlaunch [--id wndid] ClassName command [arg1]...
# A helper to launch an X application using a hotkey.
# It requires a ClassName to match the application window.
# If there are multiple applications running with the same ClassName
# the first window with matching ClassName is brought to focus and remembered.
# Thus subsequent invocations will continue bringing that remembered window to focus.
# If no existing window matches the ClassName it launches the command provided and performs
# the search again with the provided ClassName.
# If id is provided the window with id == wndid is selected if it matches the ClassName.

get_window_class()
{
	local cname
	local wnd
	wnd=$1
	xprop -id ${wnd} > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		Log "${wnd} no such window"
		return 1
	fi

	eval cname=`xprop -id ${wnd} -f WM_CLASS "8s" " \\\$0\n" WM_CLASS | awk '{print \$2}'`		

	echo -n ${cname}
	return 0
}

get_first_window_of_class()
{
	local cname
	local wnd
	for wnd in `xwininfo -root -tree | grep '^[ ]*0x' | awk '{print $1}'`
	do
		eval cname=`xprop -id ${wnd} -f WM_CLASS "8s" " \\\$0\n" WM_CLASS | awk '{print \$2}'`		
		if [ "x${cname}" = "x$1" ]
		then
			echo -n ${wnd}
			return 0
		fi
	done
	Log "${cname} no windows of this class."
	return 1
}

Log()
{
	echo `date` ":" $* | tee -a /var/log/xhotlaunch.sh.log
}

activate_window()
{
	local wcname
	wcname=`get_window_class ${wnd}`
	if [ "${wcname}" == "${cname}" ]
	then
		xdotool windowactivate ${wnd}
		echo -n ${wnd} > /tmp/xhotlaunch.wnd
		return 0
	fi
	Log "Discovered class ${wcname} doesn't match expected class ${cname}"
	return 1
}

#Script starts
wnd=""
cname=""

#Check if window id was passed in.
if [ "$1" = "--id" ]
then
	wnd=$2
	shift 2
fi

#Get the target classname
cname=$1
shift 1

if [ "$wnd" = "" ]
then
	if [ -f /tmp/xhotlaunch.wnd ]
	then
		wnd=`cat /tmp/xhotlaunch.wnd`
	else
		wnd=`get_first_window_of_class ${cname}`
	fi

fi

activate_window ${wnd} && exit 0

# At this point launch the command and expect that it causes the required window to launch and be brought to focus.
eval setsid $*	
sleep 1

wnd=`get_first_window_of_class ${cname}`
activate_window ${wnd} && exit 0

