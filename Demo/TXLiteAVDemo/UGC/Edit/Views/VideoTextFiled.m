//
//  VideoTextFiled.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/22.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "VideoTextFiled.h"
#import "UIView+Additions.h"
#import "TXColor.h"

#define kDefaultText @"点击修改文字"

@interface VideoTextFiled () <UITextViewDelegate, UITextFieldDelegate>
{
    UILabel*        _textLabel;                 //文字输入Label
    UIImageView*    _borderView;                //用来显示边框或样式背景
    UIButton*       _deleteBtn;                 //删除铵钮
    UIButton*       _styleBtn;                  //样式操作按钮，目前只改字体颜色
    UIButton*       _scaleRotateBtn;            //单手操作放大，旋转按钮
    
    //自字义键盘上的输入显示
    UITextView*     _inputTextView;
    UIButton*       _inputConfirmBtn;
    
    //用来作输助呼出键盘
    UITextField*    _hiddenTextField;
    BOOL            _isInputting;
    
    //气泡背景
    UIImageView *   _bubbleView;
    
    //己旋转角度
    CGFloat         _rotateAngle;

    NSInteger       _styleIndex;
    
    CGRect          _textNormalizationFrame;
    CGRect          _initFrame;
    BOOL            _hasSetBubble;
}

@end

@implementation VideoTextFiled

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _styleIndex = 0;
        _hasSetBubble = NO;
        _textNormalizationFrame = CGRectMake(0, 0, 1, 1);
        _initFrame = frame;
        
        _borderView = [UIImageView new];
        _borderView.layer.borderWidth = 1;
        _borderView.layer.borderColor = TXColor.cyan.CGColor;
        _borderView.userInteractionEnabled = YES;
        _borderView.backgroundColor = [UIColor clearColor];
        [self addSubview:_borderView];
        
        _bubbleView = [UIImageView new];
        [_borderView addSubview:_bubbleView];
        
        _textLabel = [UILabel new];
        _textLabel.text = kDefaultText;
        _textLabel.textColor = UIColor.blackColor;
        _textLabel.shadowOffset = CGSizeMake(2, 2);
        _textLabel.font = [UIFont systemFontOfSize:18];
        _textLabel.numberOfLines = 0;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        singleTap.numberOfTapsRequired = 1;
        _textLabel.userInteractionEnabled = YES;
        [_textLabel sizeToFit];
        [_textLabel addGestureRecognizer:singleTap];
        [_borderView  addSubview:_textLabel];
    
        
        _deleteBtn = [UIButton new];
        [_deleteBtn setImage:[UIImage imageNamed:@"videotext_delete"] forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(onDeleteBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_deleteBtn];
        
        _styleBtn = [UIButton new];
        [_styleBtn setImage:[UIImage imageNamed:@"videotext_style"] forState:UIControlStateNormal];
        [_styleBtn addTarget:self action:@selector(onStyleBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_styleBtn];
        
        _scaleRotateBtn = [UIButton new];
        [_scaleRotateBtn setImage:[UIImage imageNamed:@"videotext_rotate"] forState:UIControlStateNormal];
        UIPanGestureRecognizer* panGensture = [[UIPanGestureRecognizer alloc] initWithTarget:self action: @selector (handlePanSlide:)];
        [self addSubview:_scaleRotateBtn];
        [_scaleRotateBtn addGestureRecognizer:panGensture];
        
        UIView* inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40)];
        
        UIView* labelBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, inputAccessoryView.width - 40, inputAccessoryView.height)];
        labelBgView.backgroundColor = UIColor.whiteColor;
        labelBgView.alpha = 0.5;
        [inputAccessoryView addSubview:labelBgView];
        
        _inputTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 0, inputAccessoryView.width - 50, inputAccessoryView.height)];
        _inputTextView.textColor = UIColor.whiteColor;
        _inputTextView.font = [UIFont systemFontOfSize:18];
        _inputTextView.textAlignment = NSTextAlignmentLeft;
        _inputTextView.delegate = self;
        _inputTextView.editable = YES;
        _inputTextView.backgroundColor = UIColor.clearColor;
        [inputAccessoryView addSubview:_inputTextView];
        
        _inputConfirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(_inputTextView.right, 0, 40, inputAccessoryView.height)];
        _inputConfirmBtn.backgroundColor = TXColor.cyan;
        [_inputConfirmBtn setImage:[UIImage imageNamed:@"videotext_confirm"] forState:UIControlStateNormal];
        [_inputConfirmBtn addTarget:self action:@selector(onInputConfirmBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [inputAccessoryView addSubview:_inputConfirmBtn];
        
        
        _hiddenTextField = [[UITextField alloc] initWithFrame:CGRectZero];
        _hiddenTextField.inputAccessoryView = inputAccessoryView;
        [self addSubview:_hiddenTextField];
        
        
        UIPanGestureRecognizer* selfPanGensture = [[UIPanGestureRecognizer alloc] initWithTarget:self action: @selector (handlePanSlide:)];
        [self addGestureRecognizer:selfPanGensture];
        
        UIPinchGestureRecognizer* pinchGensture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self addGestureRecognizer:pinchGensture];
        
        UIRotationGestureRecognizer* rotateGensture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
        [self addGestureRecognizer:rotateGensture];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onKeyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textViewDidChangeValue:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:_inputTextView];
        
        
        _rotateAngle = 0.f;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGPoint center = [self convertPoint:self.center fromView:self.superview];
    
    _borderView.bounds = CGRectMake(0, 0, self.bounds.size.width - 25, self.bounds.size.height - 25);
    _borderView.center = center;
    
    _bubbleView.frame = CGRectMake(0, 0, _borderView.bounds.size.width, _borderView.bounds.size.height);
    
    _textLabel.center = CGPointMake(_bubbleView.bounds.size.width * (_textNormalizationFrame.origin.x + _textNormalizationFrame.size.width / 2), _bubbleView.bounds.size.height * (_textNormalizationFrame.origin.y + _textNormalizationFrame.size.height / 2));
    _textLabel.bounds = CGRectMake(0, 0, _bubbleView.bounds.size.width * _textNormalizationFrame.size.width, _bubbleView.bounds.size.height * _textNormalizationFrame.size.height);
    
    
    _deleteBtn.center = CGPointMake(_borderView.x, _borderView.y);
    _deleteBtn.bounds = CGRectMake(0, 0, 50, 50);
    
    _styleBtn.center = CGPointMake(_borderView.right, _borderView.top);
    _styleBtn.bounds = CGRectMake(0, 0, 50, 50);
    
    _scaleRotateBtn.center = CGPointMake(_borderView.right, _borderView.bottom);
    _scaleRotateBtn.bounds = CGRectMake(0, 0, 50, 50);
    
    if (_hasSetBubble) {
        [self calculateTextLabelFont];
    }
}

- (void)calculateTextLabelFont
{
    CGRect rect = [_textLabel.text boundingRectWithSize:CGSizeMake(_textLabel.width, MAXFLOAT) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:_textLabel.font} context:nil];
    if (rect.size.height > _textLabel.height) {
        _textLabel.font = [UIFont systemFontOfSize:_textLabel.font.pointSize - 0.1];
        [self calculateTextLabelFont];
    }
}

- (NSString*)text
{
    return _textLabel.text;
}

//生成字幕图片
- (UIImage*)textImage
{
    _borderView.layer.borderWidth = 0;
    [_borderView setNeedsDisplay];
    CGRect rect = _borderView.bounds;
    UIView *rotatedViewBox = [[UIView alloc]initWithFrame:CGRectMake(0, 0, rect.size.width , rect.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(_rotateAngle);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 0.f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotatedSize.width/2, rotatedSize.height/2);
    
    CGContextRotateCTM(context, _rotateAngle);
    
    //[_textLabel drawTextInRect:CGRectMake(-rect.size.width / 2, -rect.size.height / 2, rect.size.width, rect.size.height)];
    [_borderView drawViewHierarchyInRect:CGRectMake(-rect.size.width / 2, -rect.size.height / 2, rect.size.width, rect.size.height) afterScreenUpdates:YES];
    UIImage *rotatedImg = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    _borderView.layer.borderWidth = 1;
    _borderView.layer.borderColor = TXColor.cyan.CGColor;

    return rotatedImg;
}

//设置气泡
- (void)setTextBubbleImage:(UIImage *)image textNormalizationFrame:(CGRect)frame
{
    _bubbleView.image = image;
    if (image != nil) {
        _textNormalizationFrame = frame;
        [self calculateTextLabelFont];
        _hasSetBubble = YES;
    }else{
        _hasSetBubble = NO;
    }
    self.transform = CGAffineTransformRotate(self.transform, -_rotateAngle);
    _rotateAngle = 0;
}

//字幕图在视频预览view的frame
- (CGRect)textFrameOnView:(UIView *)view
{
    CGRect frame = CGRectMake(_borderView.x, _borderView.y, _borderView.bounds.size.width, _borderView.bounds.size.height);
    
    if (![view.subviews containsObject:self]) {
        [view addSubview:self];
        CGRect rc = [self convertRect:frame toView:view];
        [self removeFromSuperview];
        return rc;
    }
    
    return [self convertRect:frame toView:view];
}

- (CGRect)textRect
{
    CGRect rect = [_textLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 0) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:_textLabel.font} context:nil];
    //限制最小的文字框大小
    if (rect.size.width < 30) {
        rect.size.width = 30;
    } else if (rect.size.height < 10) {
        rect.size.height = 10;
    }
    
    return rect;
}

- (void)resignFirstResponser
{
    if (!_isInputting)
        return;
    
    _isInputting = NO;
    [_inputTextView resignFirstResponder];
}

- (void)onKeyboardDidShow:(NSNotification *)notification
{
    NSValue *fromRectValue = notification.userInfo[UIKeyboardFrameBeginUserInfoKey];
    CGRect fromRect = fromRectValue.CGRectValue;
    if (_isInputting) {
        if (CGRectGetMinY(fromRect) >= [UIScreen mainScreen].bounds.size.height) {
            _inputTextView.text = _textLabel.text;
        }
        [_inputTextView becomeFirstResponder];
    } else {
        if (_hiddenTextField.isFirstResponder) {
            [_hiddenTextField resignFirstResponder];
        } else {
            [self resignFirstResponder];
            [_hiddenTextField resignFirstResponder];
        }
    }
}

#pragma mark - GestureRecognizer handle
- (void)onTap:(UITapGestureRecognizer*)recognizer
{
    _isInputting = YES;
    [_hiddenTextField becomeFirstResponder];
}

- (void)handlePanSlide:(UIPanGestureRecognizer*)recognizer
{
    //拖动
    if (recognizer.view == self) {
        CGPoint translation = [recognizer translationInView:self.superview];
        CGPoint center = CGPointMake(recognizer.view.center.x + translation.x,
                                     recognizer.view.center.y + translation.y);
        if (center.x < 0) {
            center.x = 0;
        }
        else if (center.x > self.superview.width) {
            center.x = self.superview.width;
        }
        
        if (center.y < 0) {
            center.y = 0;
        }
        else if (center.y > self.superview.height) {
            center.y = self.superview.height;
        }
        
        recognizer.view.center = center;
        
        [recognizer setTranslation:CGPointZero inView:self.superview];
        
        
    }
    else if (recognizer.view == _scaleRotateBtn) {
        CGPoint translation = [recognizer translationInView:self];
        
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            //放大
            CGFloat delta = translation.x / 10;
            CGFloat newFontSize = MAX(10.0f, MIN(150.f, _textLabel.font.pointSize + delta));
            _textLabel.font = [UIFont systemFontOfSize:newFontSize];
            if (!_hasSetBubble) {
                _textLabel.bounds = [self textRect];
                self.bounds = CGRectMake(0, 0, _textLabel.bounds.size.width + 50, _textLabel.bounds.size.height + 40);
            }else{
                self.bounds = CGRectMake(0, 0, self.bounds.size.width + translation.x, self.bounds.size.height + translation.x);
            }

            //旋转
            CGPoint newCenter = CGPointMake(recognizer.view.center.x + translation.x, recognizer.view.center.y + translation.y);
            CGPoint anthorPoint = _textLabel.center;
            CGFloat height = newCenter.y - anthorPoint.y;
            CGFloat width = newCenter.x - anthorPoint.x;
            CGFloat angle1 = atan(height / width);
            height = recognizer.view.center.y - anthorPoint.y;
            width = recognizer.view.center.x - anthorPoint.x;
            CGFloat angle2 = atan(height / width);
            CGFloat angle = angle1 - angle2;
            
            self.transform = CGAffineTransformRotate(self.transform, angle);
            _rotateAngle += angle;
        }
        [recognizer setTranslation:CGPointZero inView:self];
    }
    
}

//双手指放大
- (void)handlePinch:(UIPinchGestureRecognizer*)recognizer
{
    CGFloat newFontSize = MAX(10.0f, MIN(150.f, _textLabel.font.pointSize * recognizer.scale));
    // set font size
    _textLabel.font = [_textLabel.font fontWithSize:newFontSize];
    if (!_hasSetBubble) {
        
        CGRect rect = [self textRect];
        rect = [_textLabel convertRect:rect toView:self];
        
        _textLabel.bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
        self.bounds = CGRectMake(0, 0, _textLabel.bounds.size.width + 50, _textLabel.bounds.size.height + 40);
    }else{
        self.bounds = CGRectMake(0, 0, self.bounds.size.width * recognizer.scale, self.bounds.size.height * recognizer.scale);
    }

    recognizer.scale = 1;
}

//双手指旋转
- (void)handleRotate:(UIRotationGestureRecognizer*)recognizer
{
    recognizer.view.transform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);

    _rotateAngle += recognizer.rotation;
    recognizer.rotation = 0;
}


#pragma mark - UI event handle
- (void)onInputConfirmBtnClicked:(UIButton*)sender
{
    _isInputting = NO;
    [_inputTextView resignFirstResponder];
    [_hiddenTextField resignFirstResponder];
    
    _textLabel.text = _inputTextView.text;
    
    if (!_hasSetBubble) {
        _textLabel.bounds = [self textRect];
        self.bounds = CGRectMake(0, 0, _textLabel.bounds.size.width + 50, _textLabel.bounds.size.height + 40);
    }else{
        [self calculateTextLabelFont];
    }
    
    [self.delegate onTextInputDone:_textLabel.text];
}

-(void)textViewDidChangeValue:(NSNotification *)obj{
    UITextView *textView = (UITextView *)obj.object;
    NSString *string = textView.text;
    if(string.length > 0){
        [_inputConfirmBtn setEnabled:YES];
    }else{
        [_inputConfirmBtn setEnabled:NO];
    }
}

- (void)onDeleteBtnClicked:(UIButton*)sender
{
    [self.delegate onRemoveTextField:self];
    [self removeFromSuperview];
}

- (void)onStyleBtnClicked:(UIButton*)sender
{
    [self.delegate onBubbleTap];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
