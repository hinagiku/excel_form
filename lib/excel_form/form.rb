def demo
  def add_space(i)
    '&nbsp;'*i
  end

  def arr_to_attr(object, arr)
    height = arr.size
    width = arr[0].size
    #new_arr = Array.new(height) { Array.new(width) }
    str = ''
    0.upto(height-1).to_a.each do |row|
      0.upto(width-1).to_a.each do |cell|
        if object.respond_to?(arr[row][cell]) #arr[row][cell] =~ /\p{Han}/ || arr[row][cell] == ''
          str += object.send(arr[row][cell]) ? object.send(arr[row][cell]).to_s('F') : ''
        else
          str += arr[row][cell]
        end
        str += ',' unless cell == width-1
      end
      str += '@' unless row == height-1
    end
    str
  end

  def balances_all(space, content, seq)
    %W(#{add_space(space)} #{content} start_attr#{seq} end_attr#{seq} )
  end

  @profit = Aae::FinancialStatement.find(1).profit

  @struct = []
  #@struct << %w(项目 本月数 本年累计 项目 本月数 本年累计)
  @struct << ['一、营业总收入','','',"#{add_space(4)}其中：对联营企业和合营企业的投资收益",'m_attr32','y_attr32']
  @struct << %W(#{add_space(4)}其中：营业收入 m_attr2 y_attr2 #{add_space(4)}△汇兑收益（损失以“-”号填列） m_attr33 y_attr33)
  @struct << %W(#{add_space(8)}其中：主营业务收入 m_attr3 y_attr3 三、营业利润（亏损以“-”填列） m_attr34 y_attr34)
  @struct << %W(#{add_space(12)}其他业务收入 m_attr4 y_attr4 #{add_space(4)}加：营业外收入 m_attr35 y_attr35)
  @struct << %W(#{add_space(4)}△利息收入 m_attr5 y_attr5 #{add_space(8)}其中：非流动性资产处置利得 m_attr36 y_attr36)
  @struct << %W(#{add_space(4)}△已赚保费 m_attr6 y_attr6 #{add_space(12)}非货币性资产交换利得 m_attr37 y_attr37)
  @struct << %W(#{add_space(4)}△手续费及佣金收入 m_attr7 y_attr7 #{add_space(12)}政府补助收入（补贴收入） m_attr38 y_attr38)
  @struct << ['二、营业总成本','','',"#{add_space(12)}债务重组利得",'m_attr39','y_attr39']
  @struct << %W(#{add_space(4)}其中：营业成本 m_attr9 y_attr9 #{add_space(4)}减：营业外支出 m_attr40 y_attr40)
  @struct << %W(#{add_space(8)}其中：主营业务成本 m_attr10 y_attr10 #{add_space(8)}其中：非流动性资产处置损失 m_attr41 y_attr41)
  @struct << %W(#{add_space(16)}其他业务成本 m_attr11 y_attr11 #{add_space(4)}非货币性资产交换损失（非货币性交易损失） m_attr42 y_attr42)
  @struct << %W(#{add_space(8)}△利息支出 m_attr12 y_attr12 #{add_space(12)}债务重组损失 m_attr43 y_attr43)
  @struct << %W(#{add_space(8)}△手续费及佣金支出 m_attr13 y_attr13 四、利润总额（亏损以“-”填列） m_attr44 y_attr44)
  @struct << %W(#{add_space(8)}△退保金 m_attr14 y_attr14 #{add_space(4)}减：所得税费用 m_attr45 y_attr45)
  @struct << %W(#{add_space(8)}△赔付支出净额 m_attr15 y_attr15 #{add_space(4)}加：*#未确认的投资损失 m_attr46 y_attr46)
  @struct << %W(#{add_space(8)}△提取保险合同准备金净额 m_attr16 y_attr16 五、净利润（亏损以“-”填列） m_attr47 y_attr47)
  @struct << %W(#{add_space(8)}△保单红利支出 m_attr17 y_attr17 六、归属母公司净利润 m_attr48 y_attr48)
  @struct << %W(#{add_space(8)}△分保费用 m_attr18 y_attr18 #{add_space(4)}减：*少数股东权益 m_attr49 y_attr49)
  @struct << %W(#{add_space(8)}营业税金及附加 m_attr19 y_attr19 七、每股收益 m_attr50 y_attr50)
  @struct << %W(#{add_space(8)}销售费用 m_attr20 y_attr20 #{add_space(4)}基本每股收益 m_attr51 y_attr51)
  @struct << %W(#{add_space(8)}管理费用 m_attr21 y_attr21 #{add_space(4)}稀释每股收益 m_attr52 y_attr52)
  @struct << %W(#{add_space(12)}其中：业务招待费 m_attr22 y_attr22 八、其他综合收益 m_attr53 y_attr53)
  @struct << %W(#{add_space(16)}研究与开发费 m_attr23 y_attr23 九、综合收益总额 m_attr54 y_attr54)
  @struct << %W(#{add_space(8)}财务费用 m_attr24 y_attr24 #{add_space(8)}归属于母公司所有者的综合收益总额 m_attr55 y_attr55)
  @struct << %W(#{add_space(16)}其中：利息支出 m_attr25 y_attr25 #{add_space(8)}*归属于少数股东的综合收益总额 m_attr56 y_attr56)
  @struct << ["#{add_space(24)}利息收入",'m_attr26','y_attr26','','','']
  @struct << ["#{add_space(8)}汇兑净损失（净收益以“-”号填列）",'m_attr27','y_attr27','','','']
  @struct << ["#{add_space(8)}△资产减值损失",'m_attr28','y_attr28','','','']
  @struct << ["#{add_space(8)}其他",'m_attr29','y_attr29','','','']
  @struct << ["#{add_space(4)}加：公允价值变动损益（损失以“-”填列）",'m_attr30','y_attr30','','','']
  @struct << ["#{add_space(8)}投资收益（损失以“-”填列）",'m_attr31','y_attr31','','','']
  @struct_data = arr_to_attr(@profit, @struct)
  @struct.each_index do |row|
    @struct[row] = @struct[row].join(',')
  end
  @struct = @struct.join('@')
  p @struct_data
  #p 'data'
  #p @struct_data
  @header = '项目,期初数, 期末数,项目,期初数,期末数'
  @column1 = '流动资产：,货币资金,△结算备付金'
  @column2 = '流动负债：,短期借款,△向中央银行借款'
  @aa = %w(1,2)
  respond_to { |format|
    format.html
    format.json { render :json => @aa }
  }

  @balances = []
  @balances << ['流动资产：', '', '', '流动负债：', '', '']
  @balances << balances_all(4, '货币资金', 2) + balances_all(4, '短期借款', 68)
  @balances << balances_all(4, '△结算备付金', 3) + balances_all(4, '△向中央银行借款', 69)
  @balances << balances_all(4, '△拆出资金', 4) + balances_all(4, '△吸收存款及同业存放', 70)
  @balances << balances_all(4, '交易性金融资产', 5) + balances_all(4, '△拆入资金', 71)
  @balances << balances_all(4, '△买入返售金融资产', 6) + balances_all(4, '交易性金融负债', 72)
  @balances << balances_all(4, '短期投资', 7) + balances_all(4, '应付票据', 73)
  @balances << balances_all(4, '应收票据', 8) + balances_all(4, '应付帐款', 74)
  @balances << balances_all(4, '应收帐款', 9) + balances_all(4, '预收帐款', 75)
  @balances << balances_all(6, '减：坏帐准备', 10) + balances_all(4, '△卖出回购金融资产款', 76)
  @balances << balances_all(4, '应收帐款净额', 11) + balances_all(4, '△应付手续费及佣金', 77)
  @balances << balances_all(4, '预付款项', 12) + balances_all(4, '应付职工薪酬', 78)
  @balances << balances_all(4, '应收股利', 13) + balances_all(6, '其中：应付工资', 79)
  @balances << balances_all(4, '应收利息', 14) + balances_all(8, '应付福利费', 80)
  @balances << balances_all(4, '△应收保费', 15) + balances_all(10, '#其中：职工奖励及福利基金', 81)
  @balances << balances_all(4, '△应收分保账款', 16) + balances_all(4, '应交税费', 82)
  @balances << balances_all(4, '△应收分保合同准备金', 17) + balances_all(6, '其中：应交税金', 83)
  @balances << balances_all(4, '其他应收款', 18) + balances_all(4, '应付股利', 84)
  @balances << balances_all(4, '应收补贴款', 19) + balances_all(4, '应付利息', 85)
  @balances << balances_all(4, '存货', 20) + balances_all(4, '其他应交款', 86)
  @balances << balances_all(4, '其中：△贵金属', 21) + balances_all(4, '其他应付款', 87)
  @balances << balances_all(8, '原材料', 22) + balances_all(4, '△应付分保账款', 88)
  @balances << balances_all(8, '库存商品（产成品）', 23) + balances_all(4, '△保险合同准备金', 89)
  @balances << balances_all(4, '待摊费用', 24) + balances_all(4, '△代理买卖证券款', 90)
  @balances << balances_all(4, '一年内到期的长期债券投资', 25) + balances_all(4, '△代理承销证券款', 91)
  @balances << balances_all(4, '其他流动资产', 26) + balances_all(4, '预提费用', 92)
  @balances << balances_all(0, '流动资产合计', 27) + balances_all(4, '一年内到期的长期负债', 93)
  @balances << ['非流动资产：', '', '', '其他流动负债', 'start_attr94', 'end_attr94']
  @balances << balances_all(4, '△发放贷款及垫款', 29) + balances_all(0, '流动负债合计', 95)
  @balances << ["#{add_space(4)}可供出售金融资产", 'start_attr30', 'end_attr30', '非流动负债：', '', '']
  @balances << balances_all(4, '持有至到期投资', 31) + balances_all(4, '长期借款', 97)
  @balances << balances_all(4, '长期应收款', 32) + balances_all(4, '应付债券', 98)
  @balances << balances_all(4, '长期股权投资', 33) + balances_all(4, '专项应付款', 99)
  @balances << balances_all(4, '长期债权投资', 34) + balances_all(4, '预计负债', 100)
  @balances << balances_all(4, '投资性房地产', 35) + balances_all(4, '递延所得税负债', 101)
  @balances << balances_all(4, '固定资产原价', 36) + balances_all(6, '其他非流动负债', 102)
  @balances << balances_all(6, '减：累计折旧', 37) + balances_all(6, '其中：特准储备基金', 103)
  @balances << balances_all(6, '固定资产净值', 38) + balances_all(0, '非流动负债合计', 104)
  @balances << balances_all(6, '减：固定资产减值准备', 39) + balances_all(4, '负债合计', 105)
  @balances << ["#{add_space(4)}固定资产净额", 'start_attr40', 'start_attr40', '所有者权益(或股东权益)：', '', '']
  @balances << balances_all(4, '工程物资', 41) + balances_all(4, '实收资本(或股本)', 107)
  @balances << balances_all(4, '在建工程', 42) + balances_all(4, '国家资本', 108)
  @balances << balances_all(4, '固定资产清理', 43) + balances_all(4, '法人资本', 109)
  @balances << balances_all(4, '生产性生物资产', 44) + balances_all(6, '其中：国有法人资本', 110)
  @balances << balances_all(4, '油气资产', 45) + balances_all(6, '集体法人资本', 111)
  @balances << balances_all(4, '无形资产', 46) + balances_all(4, '个人资本', 112)
  @balances << balances_all(4, '开发支出', 47) + balances_all(4, '外商资本', 113)
  @balances << balances_all(4, '商誉', 48) + balances_all(6, '#减：已归还投资', 114)
  @balances << balances_all(4, '长期待摊费用', 49) + balances_all(4, '实收资本(或股本)净额', 115)
  @balances << balances_all(4, '其他长期资产', 50) + balances_all(4, '资本公积', 116)
  @balances << balances_all(4, '递延所得税资产', 51) + balances_all(6, '减：库存股', 117)
  @balances << balances_all(6, '其他非流动资产', 52) + balances_all(4, '专项储备', 118)
  @balances << balances_all(0, '非流动资产合计', 53) + balances_all(4, '盈余公积', 119)
  @balances << ["#{add_space(4)}固定资产净额", 'start_attr40', 'start_attr40', '所有者权益(或股东权益)：', '', '']


  #@sam_work_cards = Sam::WorkCard.all
  #respond_with(@sam_work_cards) do |format|
  #  format.json { render :json => CardsTable.new(@sam_work_cards).as_json }
  #end
end

def save_demo
  def string_to_arr(string)
    arr = string.split('@')
    arr.each do |a|
      arr[arr.index(a)] = a.split(',',-1)
    end
  end

  new = string_to_arr(params[:new_data])
  old = string_to_arr(params[:old_data])
  object = Aae::FinancialStatement.find(1).profit
  (0..old.size-1).to_a.each do |i|
    (0..old[i].size-1).to_a.each do |j|
      if !old[i][j].blank? && object.respond_to?(old[i][j])
        if new[i][j].blank?
          object.update_attribute(old[i][j],nil)
        else
          object.update_attribute(old[i][j],new[i][j])
        end
      end
    end
  end

  render :text=>object.inspect
end