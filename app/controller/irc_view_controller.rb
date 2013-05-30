class IRCViewController < UIViewController
  attr_reader :webView, :container
  def viewDidLoad
    super
    @host = 'hubbard.freenode.net'
    @port = 6667
    @name = "rubymotionkun"
    @channel = "#ninjinkun"
    @irc = IRC::Connection.new(host: @host, port: @port, delegate: self, name: @name)
    @irc.connect()
    setupViews
    registerNotifications
  end

  def registerNotifications
    PHFComposeBarViewWillChangeFrameNotification.add_observer(self,'composeBarViewWillChangeFrame:')
    UIKeyboardWillShowNotification.add_observer(self, 'keyboardWillToggle:')
    UIKeyboardWillHideNotification.add_observer(self, 'keyboardWillToggle:')
  end

  def setupViews
    viewBounds = self.view.bounds;

    @container = UIView.alloc.initWithFrame(viewBounds)

    @webView = UIWebView.alloc.initWithFrame([[0, 0], [self.view.bounds.size.width, self.view.bounds.size.height - 40]])
    @webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
    @webView.delegate = self
    @container.addSubview(@webView)

    @composeBarView = PHFComposeBarView.alloc.initWithFrame([[0.0, viewBounds.size.height - 40.0], [viewBounds.size.width, 40.0]])
    @composeBarView.delegate = self
    @container.addSubview(@composeBarView)

    @container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
    self.view.addSubview(@container)
  end

  def webViewDidFinishLoad(webView)
    scrollToBottom
  end

  def scrollToBottom
    bottomOffset = CGPointMake(0, @webView.scrollView.contentSize.height - @webView.scrollView.bounds.size.height);
    @webView.scrollView.setContentOffset(bottomOffset, animated: false);
  end

  def renderMessages(messages)
    messages.map! do |variables|
      hash = {}
      hash["message"] = variables.params.join(' ')
      hash["notice"] = variables.command == 'NOTICE'
      variables.instance_variables.each {|var| hash[var.to_s.delete("@")] = variables.instance_variable_get(var) }
      hash
    end
    template = <<HTML
<html>
<head>
<meta name="viewport" content="width=device-width, minimum-scale=1, maximum-scale=1">
</head>
<body>
{% FOR messages %}
<p><span style="color:red;">{% nick %}</span> <span style="color:green;">{% command %}</span> {% message %}</p>
{% END %}
</body>
</html>
HTML
    html = Template.new(template).render("messages" => messages)

    @webView.loadHTMLString(html, baseURL: nil)
  end

  def irc(ifc ,didReceiveMessages: messages)
    renderMessages(messages)
  end

  def composeBarViewDidPressButton(composeBarView)
      @irc.join_channel(@channel)
      @irc.send_channel(@channel, composeBarView.text)
      composeBarView.resignFirstResponder
      composeBarView.text = nil
  end

  # handle keyboard layout
  def keyboardWillToggle(notification)
    userInfo = notification.userInfo
    duration = userInfo[UIKeyboardAnimationDurationUserInfoKey].floatValue
    animationCurve = userInfo[UIKeyboardAnimationDurationUserInfoKey].intValue
    startFrame = userInfo[UIKeyboardFrameBeginUserInfoKey].CGRectValue
    endFrame = userInfo[UIKeyboardFrameEndUserInfoKey].CGRectValue

    signCorrection = 1;
    if (startFrame.origin.y < 0 || startFrame.origin.x < 0 || endFrame.origin.y < 0 || endFrame.origin.x < 0)
       signCorrection = -1
    end

    widthChange  = (endFrame.origin.x - startFrame.origin.x) * signCorrection
    heightChange = (endFrame.origin.y - startFrame.origin.y) * signCorrection

    sizeChange = (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) ? widthChange : heightChange

    newContainerFrame = @container.frame
    newContainerFrame.size.height += sizeChange;

    offsetY = [0.0, self.webView.scrollView.contentSize.height - self.webView.scrollView.frame.size.height - sizeChange].max
    newTextViewContentOffset = [0, offsetY];

    UIView.animateWithDuration(duration, delay: 0, options: animationCurve|UIViewAnimationOptionBeginFromCurrentState, animations: lambda do
        @container.frame = newContainerFrame
        end, completion: nil)
    self.webView.scrollView.setContentOffset(newTextViewContentOffset, animated: true)
  end

  def composeBarViewWillChangeFrame(notification)
    userInfo = notification.userInfo
    duration = userInfo[PHFComposeBarViewAnimationDurationUserInfoKey].floatValue
    animationCurve = userInfo[PHFComposeBarViewAnimationDurationUserInfoKey].intValue
    startFrame = userInfo[PHFComposeBarViewFrameBeginUserInfoKey].CGRectValue
    endFrame = userInfo[PHFComposeBarViewFrameEndUserInfoKey].CGRectValue

    heightChange = endFrame.size.height - startFrame.size.height;

    newTextViewFrame = self.webView.scrollView.frame;
    newTextViewFrame.size.height -= heightChange;

    offsetY = [0.0, self.webView.scrollView.contentSize.height - newTextViewFrame.size.height].max;
    newTextViewContentOffset = [0, offsetY]

    UIView.animateWithDuration(duration, delay: 0, options: animationCurve|UIViewAnimationOptionBeginFromCurrentState, animations: lambda do
                        self.webView.scrollView.frame = newTextViewFrame
                        self.webView.scrollView.contentOffset = newTextViewContentOffset
        end,completion: nil)
    end
end

