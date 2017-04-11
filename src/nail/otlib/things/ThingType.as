///////////////////////////////////////////////////////////////////////////////////
// 
//  Copyright (c) 2014 Nailson <nailsonnego@gmail.com>
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
///////////////////////////////////////////////////////////////////////////////////

package nail.otlib.things
{
    import nail.otlib.utils.ThingUtils;
    
    public class ThingType
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        public var id:uint;
        public var category:String;
		// jano edit
		public var hasGroups:Boolean;
		public var groups:uint;		
		// end  jano
        public var width:uint;
        public var height:uint;
        public var exactSize:uint;
        public var layers:uint;
        public var patternX:uint;
        public var patternY:uint;
        public var patternZ:uint;
        public var frames:uint;
        public var spriteIndex:Vector.<uint>;
		// THOSE ARE ONLY USED IF HAS MORE THAN 1 GROUP ( 2 LOL )
        public var width_2:uint;
        public var height_2:uint;
        public var exactSize_2:uint;
        public var layers_2:uint;
        public var patternX_2:uint;
        public var patternY_2:uint;
        public var patternZ_2:uint;
        public var frames_2:uint;
        public var spriteIndex_2:Vector.<uint>;		
		// -- -- -- -- -- -- -- --
        public var isGround:Boolean;
        public var groundSpeed:uint;
        public var isGroundBorder:Boolean;
        public var isOnBottom:Boolean;
        public var isOnTop:Boolean;
        public var isContainer:Boolean;
        public var stackable:Boolean;
        public var forceUse:Boolean;
        public var multiUse:Boolean;
        public var hasCharges:Boolean;
        public var writable:Boolean;
        public var writableOnce:Boolean;
        public var maxTextLength:uint;
        public var isFluidContainer:Boolean;
        public var isFluid:Boolean;
        public var isUnpassable:Boolean;
        public var isUnmoveable:Boolean;
        public var blockMissile:Boolean;
        public var blockPathfind:Boolean;
        public var noMoveAnimation:Boolean;
        public var pickupable:Boolean;
        public var hangable:Boolean;
        public var isVertical:Boolean;
        public var isHorizontal:Boolean;
        public var rotatable:Boolean;
        public var hasLight:Boolean;
        public var lightLevel:uint;
        public var lightColor:uint;
        public var dontHide:Boolean;
        public var isTranslucent:Boolean;
        public var floorChange:Boolean;
        public var hasOffset:Boolean;
        public var offsetX:uint;
        public var offsetY:uint;
        public var hasElevation:Boolean;
        public var elevation:uint;
        public var isLyingObject:Boolean;
        public var animateAlways:Boolean;
        public var miniMap:Boolean;
        public var miniMapColor:uint;
        public var isLensHelp:Boolean;
        public var lensHelp:uint;
        public var isFullGround:Boolean;
        public var ignoreLook:Boolean;
        public var cloth:Boolean;
        public var clothSlot:uint;
        public var isMarketItem:Boolean;
        public var marketName:String;
        public var marketCategory:uint;
        public var marketTradeAs:uint;
        public var marketShowAs:uint;
        public var marketRestrictProfession:uint;
        public var marketRestrictLevel:uint;
        public var hasDefaultAction:Boolean;
        public var defaultAction:uint;
        public var usable:Boolean;
		
		// -- -- -- -- --
		public var isAnimation:Boolean;
		public var animationMode:int;
		public var frameStrategy:int;
		public var startFrame:int;
		public var frameDurations:Vector.<FrameDuration>;
		
		public var isAnimation_2:Boolean;
		public var animationMode_2:int;
		public var frameStrategy_2:int;
		public var startFrame_2:int;
		public var frameDurations_2:Vector.<FrameDuration>;
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ThingType()
        {
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function toString():String
        {
            return "[object ThingType category=" + this.category + ", id=" + this.id + "]";
        }
        
        public function clone():ThingType
        {
            return ThingUtils.copyThing(this);
        }
    }
}
