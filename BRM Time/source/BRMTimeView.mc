import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

class BRMTimeView extends WatchUi.DataField {

	hidden var tt as Numeric;			// swap display		number
	
	hidden var dfWidth as Numeric;		// 필드 폭			number
	hidden var dfHeight as Numeric;		// 필드 높이			number

	hidden var dispDF as Numeric;		// 메인 표시 설정		number
	hidden var dispTR as Numeric;		// 오른쪽 위 표시 설정

	hidden var tgSpd as Numeric;		// 목표 속도	m/s		float
	
	hidden var maxDis as Numeric;		// 코스거리? 	meter	float
	hidden var gtDis as Numeric;		// 남은거리	meter	float
	hidden var elsdDis as Numeric;		// 이동거리	meter	float
	hidden var elsdTime as Numeric;		// 경과시간	msec	number > float
	
	hidden var limitTime as Numeric;	// 제한시간	min		number
	hidden var remains as Numeric;		// 남은시간	min		number
	
	hidden var edgeModel as Numeric;	// 폰트크기

    function initialize() {
        DataField.initialize();
        tt = 0;
        
        dfWidth = 140;
        dfHeight = 92;
        
        dispDF = 0;
        dispTR = 0;
        
        tgSpd = 0.0f;
        maxDis = 0.0f;
        gtDis = 0.0f;
        elsdDis = 0.0f;
        elsdTime = 0.0f;
        
        limitTime = 0;
        remains = 0;
        
        edgeModel = 0;
    }

    function onLayout(dc as Dc) as Void {
    	dfWidth = dc.getWidth();
    	dfHeight = dc.getHeight();
    	var fHeight = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM);
    	switch (dfWidth) {
    	case 140 :
    	case 282 :
    		if (fHeight == 48) { edgeModel = 1040; }
    		else { edgeModel = 1030; }
			break;
		default :
		}
    	readProperties();
    }

	function readProperties() {

		var targetSpd;
		var userSpd;
		var useDist2Dest;
		var dist2Dest;
	   	if (Application has :Properties) {
    		dispDF = Application.Properties.getValue("dispDF");
    		dispTR = Application.Properties.getValue("topRight");
    		targetSpd = Application.Properties.getValue("targetSpeed");
    		userSpd = Application.Properties.getValue("userSPEED").toFloat();
			useDist2Dest = Application.Properties.getValue("useDist2Dest");
			dist2Dest = Application.Properties.getValue("dist2Dest").toFloat() * 1000.0f;
    	} else {
    		dispDF = 2;
    		dispTR = 0;
    		targetSpd = 0.0f;
    		userSpd = 0.0f;
    		useDist2Dest = false;
    		dist2Dest = 0.0f;
    	}
    	if (targetSpd != 0 && userSpd != 0) {
    		switch(targetSpd) {
    			case 0:
    				tgSpd = 15.0f;
    				break;
    			case 1:
    				tgSpd = 13.33f;
    				break;
    			case 2:
    				tgSpd = 10.0f;
    				break;    			
    			case 3:
    				tgSpd = 18.0f;
    				break;    			
    			default:
    				tgSpd = userSpd;
    		}
    	} else {
    		tgSpd = 15.0f;
    	}
    	if (dist2Dest != 0 && useDist2Dest) {
    		maxDis = dist2Dest;
    	}
	}
	
    function compute(info as Activity.Info) as Void {
		tt++;
		if (tt>5) { tt = 0; }
		
		// Distance to Destination : meter, float
		if (info has :distanceToDestination && info.distanceToDestination != null) {
			gtDis = info.distanceToDestination;
		} else { gtDis = 0.0f; }
		//if (gtDis == 0) { tt=2; }
		// Elapsed Distance : meter, float
		if (info has :elapsedDistance && info.elapsedDistance != null) {
			elsdDis = info.elapsedDistance;
		} else { elsdDis = 0.0f; }
		// Elapsed Time : milli => second, number => float
		if (info has :elapsedTime && info.elapsedTime != null) {
			elsdTime = (info.elapsedTime.toFloat())/1000.0f;
		} else { elsdTime = 0.0f; }
		
		if (maxDis < gtDis) {
			maxDis = gtDis;
		}

		// 제한시간(분)
		if (maxDis > 0){
			var totalTime = Math.round(maxDis / 1000.0 / tgSpd * 60.0f).toNumber();
			limitTime = totalTime;
		} else { limitTime = 0; }

		// 남은시간(분)
		if (gtDis > 100 && limitTime > 0){
			remains = (limitTime - elsdTime / 60).toNumber();
		} else if (gtDis == 0) {
			remains = 1;
		} else {
			remains = 0;
		}
		//System.println(limitTime + ", " + gtDis + ", " + remains);
    }

    function onUpdate(dc as Dc) as Void {

		var backgroundColor = getBackgroundColor();
		var txtColor;

		if (backgroundColor == Graphics.COLOR_BLACK) {
			txtColor = Graphics.COLOR_WHITE;
		} else {
			txtColor = Graphics.COLOR_BLACK;
		}
		
		// 화면 초기화(지우기)
		dc.setColor(txtColor, backgroundColor);
		dc.clear();

		dc.setColor(txtColor, -1);
		
		dfWidth = dc.getWidth();
		dfHeight = dc.getHeight();
		
		var center = dfWidth * 0.5;
		var vcenter = dfHeight * 0.7;
		
		var clockTime = System.getClockTime();
		var timeHH = 0;
		var	timeMM = 0;

		
		var elTime = 0; 
		if (elsdTime > 3600) { 
			elTime = (elsdTime/60).toNumber();
		} else {
			elTime = elsdTime.toNumber();
		}
		var isNotDest = (remains > 0);
		
		//isNotDest = false;		
		switch(dispDF) {
			// 시계
			case 0:
				timeHH = clockTime.hour;
				timeMM = clockTime.min;
				break;
			// 남은시간
			case 1:
				if (isNotDest) {
					timeHH = remains / 60;
					timeMM = remains % 60;
				}
				break;
			// 경과시간
			case 2:
				timeHH = elTime / 60;
				timeMM = elTime % 60;
				break;
			// 번갈아 보여주기 (경과시간, 남은시간)
			case 3:
				switch(tt) {
					case 0:
					case 1:
					case 2:
						timeHH = elTime / 60;
						timeMM = elTime % 60;
						break;
					case 3:
					case 4:
					case 5:
						if (isNotDest) {
							timeHH = remains / 60;
							timeMM = remains % 60;
						}
						break;
					default:
					break;
				}
				break;
			// 번갈아 보여주기 (현재시간, 남은시간)
			case 4:
				switch(tt) {
					case 0:
					case 1:
					case 2:
						timeHH = clockTime.hour;
						timeMM = clockTime.min;
						break;
					case 3:
					case 4:
					case 5:
						if (isNotDest) {
							timeHH = remains / 60;
							timeMM = remains % 60;
						}
						break;
					default:
					break;
				}
				break;
			// 번갈아 보여주기 (현재시간, 경과시간)
			case 5:			
				switch(tt) {
					case 0:
					case 1:
					case 2:
						timeHH = clockTime.hour;
						timeMM = clockTime.min;
						break;
					case 3:
					case 4:
					case 5:
						timeHH = elTime / 60;
						timeMM = elTime % 60;
						break;
					default:
					break;
				}
				break;
			default:
		}
		
		var unitK = "";
		if (gtDis/1000 < 1000) { unitK = "k"; }

		var HH_len = 0;
		var MM_len = 0;
		var timeText = "";
		switch(edgeModel) {
		case 1040:
			if (isNotDest) {
				HH_len = dc.getTextWidthInPixels(timeHH.format("%d"),Graphics.FONT_NUMBER_HOT);
				MM_len = dc.getTextWidthInPixels(":"+timeMM.format("%02d"), Graphics.FONT_NUMBER_MEDIUM);
				var time_len = (HH_len + MM_len) * 0.5;
				dc.drawText(center - time_len, vcenter, Graphics.FONT_NUMBER_HOT, timeHH.format("%d"), Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
				dc.drawText(center - time_len + HH_len, vcenter + dfHeight * 0.05, Graphics.FONT_NUMBER_MEDIUM, ":" + timeMM.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
			} else {
				timeText = loadResource(Rez.Strings.nearDest);
				dc.drawText(center, vcenter, Graphics.FONT_MEDIUM, timeText, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			}

			dc.drawText(dfWidth * 0.03, dfHeight * 0.22, Graphics.FONT_LARGE, (gtDis/1000).format("%d") + unitK, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
			
			switch(dispTR) {
			case 0:
				drawBatteryText(dc, 0.97, 0.22);	
				break;
			default:
				drawLimitSpeedText(dc, 0.97, 0.22);
			}	
			break;
		default:
			if (isNotDest) {
				timeText = Lang.format("$1$:$2$", [timeHH, timeMM.format("%02d")]);
				dc.drawText(center, vcenter, Graphics.FONT_NUMBER_MEDIUM, timeText, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			} else {
				timeText = loadResource(Rez.Strings.nearDest);
				dc.drawText(center, vcenter, Graphics.FONT_MEDIUM, timeText, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			}			
			dc.drawText(dfWidth * 0.03, dfHeight * 0.22, Graphics.FONT_MEDIUM, (gtDis/1000).format("%d") + unitK, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
			switch(dispTR) {
			case 0:
				drawBatteryText(dc, 0.97, 0.22);
				break;	
			default:
				drawLimitSpeedText(dc, 0.97, 0.22);
			}	
		}
		
/*		vcenter = dfHeight * 0.3;
		timeHH = clockTime.hour;
		timeMM = clockTime.min;
		timeTxt = Lang.format("$1$:$2$", [timeHH, timeMM.format("%02d")]);
		dc.drawText(center, vcenter, Graphics.FONT_NUMBER_MEDIUM, timeTxt, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		
		vcenter = dfHeight * 0.5;
		timeHH = remains / 60;
		timeMM = remains % 60;
		timeTxt = Lang.format("$1$:$2$", [timeHH, timeMM.format("%02d")]);
		dc.drawText(center, vcenter, Graphics.FONT_NUMBER_MEDIUM, timeTxt, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
		
		vcenter = dfHeight * 0.7;
		remains = Math.round(gtDis / tgSpd * 60.0f).toNumber();
		timeHH = remains / 60;
		timeMM = remains % 60;
		timeTxt = Lang.format("$1$:$2$", [timeHH, timeMM.format("%02d")]);
		dc.drawText(center, vcenter, Graphics.FONT_NUMBER_MEDIUM, timeTxt, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

		vcenter = dfHeight * 0.9;
		timeTxt = elDis.format("%d") + "km";
		dc.drawText(center, vcenter, Graphics.FONT_NUMBER_MEDIUM, timeTxt, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
*/		
    }
    
    function drawLimitSpeedText(dc as Dc, x as Numeric, y as Numeric) as Void {
//		var unit;
//		var ddd = tgSpd * 10 - tgSpd.toNumber() * 10;
//		if (ddd > 0) {
//			unit = "." + ddd.format("%d");
//		} else {
//			unit = "k";
//		}
		var targetSpeedText = tgSpd.format("%.1f");
		dc.drawText(dfWidth * x, dfHeight * y, Graphics.FONT_MEDIUM, targetSpeedText, Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
    }

	function drawBatteryText(dc as Dc, x as Numeric, y as Numeric) as Void {
		//var backgroundColor = getBackgroundColor();
		// 배경에 따른 글자, 배터리, GPS 색상 지정
		//var txtColor;
		//if (backgroundColor == Graphics.COLOR_BLACK) {
		//	txtColor = Graphics.COLOR_WHITE;
		//} else {
		//	txtColor = Graphics.COLOR_BLACK;
		//}
		//dc.setColor(txtColor, -1);
		var unit;
		var battery = System.getSystemStats().battery;	// Float 변수
		if (battery != 100) {
			unit = "%";
		} else {
			unit = "";
		}
		switch (edgeModel) {
		case 1040 :
			dc.drawText(dfWidth * x, dfHeight * y, Graphics.FONT_MEDIUM, battery.format("%d") + unit, Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
			break;
		default :
			dc.drawText(dfWidth * x, dfHeight * y, Graphics.FONT_MEDIUM, battery.format("%d") + unit, Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}    

	// 배터리 아이콘 그리기
	function drawBattery(dc as Dc) as Void{
		var backgroundColor = getBackgroundColor();
		// 배경에 따른 글자, 배터리, GPS 색상 지정
		var greenColor, redColor, yellowColor, grayColor;
		// 배경이 흑색이면 밝은 컬러
		if (backgroundColor == Graphics.COLOR_BLACK) {
			greenColor = Graphics.COLOR_GREEN;
			redColor = Graphics.COLOR_RED;
			yellowColor = Graphics.COLOR_YELLOW;
			grayColor = Graphics.COLOR_DK_GRAY;
		// 배경이 흰색이면 어두운 컬러
		} else {
			greenColor = Graphics.COLOR_DK_GREEN;
			redColor = Graphics.COLOR_DK_RED;
			yellowColor = Graphics.COLOR_ORANGE;
			grayColor = Graphics.COLOR_LT_GRAY;
		}
		// 배터리 상태 가져오기
		var battery = System.getSystemStats().battery;	// Float 변수
		
		var x = dfWidth*0.88;
		var y = dfHeight*0.15;
		var width = dfWidth * 0.1;
		var height = dfHeight * 0.19;
		var cap = width * 0.15;
		var x2 = x + cap;
		var y2 = y - cap * 1.5;
		var width2 = width - cap * 2;
		// 배터리 아이콘 외곽선 그리기
		dc.setColor(grayColor, -1);
    	dc.drawRectangle(x,y,width,height);
    	dc.drawRectangle(x2, y2, width2, cap * 1.5 + 1);
		// 배터리 용량별 색상 지정		
		if (battery < 15) {
			dc.setColor(redColor, -1);
		} else if(battery < 30) {
			dc.setColor(yellowColor, -1);
		} else if(battery == 100) {
			dc.setColor(greenColor, -1);
			// 100% 일 때 전극 채우기 
			dc.fillRectangle(x2, y2, width2, cap * 1.5 + 1);
    	} else {
			dc.setColor(greenColor, -1);
		}
		// 배터리 용량에 따라 색상 채우기
		// 계산 반올림 문제로 맨 아래 한픽셀이 가려지지 않는 문제가 있음
    	dc.fillRectangle(x, y + height*(1.0-battery/100.0), width, height*(battery/100.0));
    }
}