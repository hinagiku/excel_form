#coding:utf-8

module ExcelForm
  class Ef
    attr_accessor :digit, :sum_arr, :headers, :auto_complete, :struct_string, :struct_data, :struct, :resource

    def initialize
      @digit ||= 2
      @sum_arr ||= []
      @headers ||= Array.new(6).map { ['1', 100, true] }
      @struct = @struct || ('0,0,0,0,0,0@'*6).chop
    end

    def struct_data
      arr_to_attr(resource, struct.dup)
    end

    def struct_data=(value)
      @struct_data = value
    end

    def struct_string
      arr_to_struct(struct.dup)
    end

    def struct_string=(value)
      @struct_string = value
    end

    def arr_to_attr(object, arr)
      height = arr.size
      width = arr[0].size
      str = ''
      0.upto(height-1).to_a.each do |row|
        0.upto(width-1).to_a.each do |cell|
          if object.respond_to?(arr[row][cell])
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

    def arr_to_struct(arr)
      arr.each_index do |row|
        arr[row] = arr[row].join(',')
      end
      arr.join('@')
    end

    def form_builder
      col_num = self.headers.size
      attr_validate
      result =<<JSCRIPT
        //转换千分符
    #{decimal_digit(digit)}
    //验证
    #{self.sum_validate(sum_arr, col_num)}

    //grid
    var grid;
    var data = [];
    var options = {
        editable: true,
        enableAddRow: false,
        //鼠标可以点击格
        enableCellNavigation: true,
        enableAsyncPostRender: true,//
        autoHeight: true,//
        autoEdit: false,
        cellHighlightCssClass: "highlight",
        cellFlashingCssClass: "flashing",
        defaultFormatter: function (row, cell, value, columnDef, dataContext) {
            if (value == null)
                return '';
            //页面上又进行了一次编码，所以&nbsp传过来是&amp;nbsp;，要进行解码
            return $('<div/>').html(value).text();
        }
    };
    //标题
    var columns = [];
    #{self.generate_header(headers)}

    function FormulaEditor(args) {
        var _self = this;
        var _editor = new Slick.Editors.Text(args);
        var _selector;

        $.extend(this, _editor);

        function init() {
            // register a plugin to select a range and append it to the textbox
            // since events are fired in reverse order (most recently added are executed first),
            // this will override other plugins like moverows or selection model and will
            // not require the grid to not be in the edit mode
            _selector = new Slick.CellRangeSelector();
            _selector.onCellRangeSelected.subscribe(_self.handleCellRangeSelected);
            args.grid.registerPlugin(_selector);
        }

        this.destroy = function () {
            _selector.onCellRangeSelected.unsubscribe(_self.handleCellRangeSelected);
            grid.unregisterPlugin(_selector);
            _editor.destroy();
        };

        this.handleCellRangeSelected = function (e, args) {
            _editor.setValue(
                    _editor.getValue() +
                            grid.getColumns()[args.range.fromCell].name +
                            args.range.fromRow +
                            ":" +
                            grid.getColumns()[args.range.toCell].name +
                            args.range.toRow
            );
        };


        init();
    }

    function formatThousandChar() {
        //自动填充
        #{self.auto_write(auto_complete, col_num)}

        //调用转换千分符
        for (var i = 0; i < 100; i++) {
            for (var j = 0; j < 100; j++) {
                if (grid.getCellNode(i, j) != null) {
                    var val = grid.getCellNode(i, j).innerHTML;
                    if (!isNaN(val) && val != 0) {
                        grid.getCellNode(i, j).innerHTML = cc(val);
                    }
                }
            }
        }
        //输入错误高亮闪烁
        #{self.change_css(sum_arr, col_num)}
    }

    $(function () {
        var str = '#{self.struct_data}';
        var arr = str.split('@');
        for (var i = 0; i < arr.length; i++) {
            var a = arr[i].split(',');
            var d = (data[i] = {});
            for (var j = 0; j < a.length; j++) {
                d[j] = a[j];
              //if(i==0){alert(d[j]);}
            }

        }
        grid = new Slick.Grid("##{self.object_id}", data, columns, options);

        #{self.flash_cell(sum_arr, col_num)}

        grid.setSelectionModel(new Slick.CellSelectionModel());
        grid.registerPlugin(new Slick.AutoTooltips());

        // set keyboard focus on the grid
        grid.getCanvasNode().focus();

        var copyManager = new Slick.CellCopyManager();
        grid.registerPlugin(copyManager);
        //excel式的复制粘贴
        copyManager.onPasteCells.subscribe(function (e, args) {
            if (args.from.length !== 1 || args.to.length !== 1) {
                throw "This implementation only supports single range copy and paste operations";
            }

            var from = args.from[0];
            var to = args.to[0];
            var val;
            for (var i = 0; i <= from.toRow - from.fromRow; i++) {
                for (var j = 0; j <= from.toCell - from.fromCell; j++) {
                    if (i <= to.toRow - to.fromRow && j <= to.toCell - to.fromCell) {
                        val = data[from.fromRow + i][columns[from.fromCell + j].field];
                        if (!isNaN(val)) {
                            data[to.fromRow + i][columns[to.fromCell + j].field] = val;
                            grid.invalidateRow(to.fromRow + i);
                        }
                    }


                }
            }
            grid.render();
        });

        var handleValidationError = function (e, args) {
            var validationResult = args.validationResults;
            var activeCellNode = args.cellNode;
            var errorMessage = validationResult.msg
            var valid_result = validationResult.valid;
            if (!valid_result) {
                $(activeCellNode).attr("title", errorMessage);
            }
            else {
                //修改源码，让验证为true时也能执行这个方法
                $(activeCellNode).attr("title", "");
            }
            poshytip(activeCellNode);


        }

        function poshytip(obj) {
            $(obj).poshytip({showTimeout: 1});
        }

        var destroyTip = function (e, args) {
            var editor = args.editor;
            alert(editor.attr('das'));
            $(editor).attr("title","");
        }

        grid.onValidationError.subscribe(handleValidationError);

    })
    function hasClass(ele,cls) {
        return ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)'));
    }
    //数据有误，不能提交
    function submitFun() {
        //var check = true;
        var data_str = '';
        for (var i = 0; i < data.length; i++) {
            for (var j = 0; j < #{col_num}; j++) {
                //判断是否有元素高亮
                //if(hasClass(grid.getCellNode(i, j), "highlight")) {
                    //check = false;
                //}
                //拼成数据
                data_str += data[i][j];
                if (j != #{col_num-1}) {
                    data_str += ','
                }
            }
            data_str += '@';
        }
        if ($('##{self.object_id}').prevAll().length == 0) {
            $("#new_data").val(data_str);
            $('form').submit();
        }
        else {
            alert('请确认数据的正确性！');
        }

    }

JSCRIPT
      result
    end

    def attr_validate
      begin
        if !digit.is_a?(Integer)
          raise ArgumentError, '小数位数digit必须是整数！'
        end
        #if !eval struct_data.split('@').map {|d| d.split(',').size == struct_data.split('@')[0].split(',').size}.join(' && ')
        #  raise ArgumentError, '数据struct_data每行个数必须相同！'
        #end
        #if !eval sum_arr.map {|s| p s.size == 3}.join(' && ')
        #  raise ArgumentError, '验证数组sum_arr结构必须为[和位置，相加位置的数组，错误提醒字符串]！'
        #end
      end
    end

    def get_cell(position, col_num, type=false)
      a, b = position.divmod(col_num)
      type ? "#{a}, #{b}" : "data[#{a}][#{b}]"
    end

    def conv_s(a, col_num)
      if a.respond_to?('join')
        result = '0'
        a.each { |num| result += "+parseFloat(#{get_cell(num, col_num)})" }
        result
      else
        get_cell(a, col_num)
      end
    end

    def decimal_digit(digit)
      result =<<-DDJS
        function cc(s) {
        if (/[^0-9\\.]/.test(s)) return "";
        s = s.replace(/^(\\d*)$/, "$1.");
        s = (s + "#{'0'*digit}").replace(/(\\d*\\.#{'\d'*digit})\\d*/, "$1");
        s = s.replace(".", ",");
        var re = /(\\d)(\\d{3},)/;
        while (re.test(s))
            s = s.replace(re, "$1,$2");
        s = s.replace(/,(#{'\d'*digit})$/, ".$1");
        return s.replace(/^\\./, "0.")
        }
      DDJS
      result
    end

    def sum_validate(arr, col_num)
      str = ''
      arr.each do |a|
        if a.size == 2
          left = conv_s(a[0], col_num)
          right = conv_s(a[1], col_num)
          str += "if (#{left} != #{right}) {return {valid:true, msg:''};}"
        end

      end
      result =<<-SVJS
    function FieldValidator(value) {
        if (isNaN(value)) {
            return {valid: false, msg: "只能输入数字！"};
        } else {
            #{str}
            return {valid: true, msg: null};
        }
    }
      SVJS
      result
    end

    def change_css(arr, col_num)
      result = ''
      arr.each do |a|
        if a.size == 3
          left = conv_s(a[0], col_num)
          right = conv_s(a[1], col_num)
          light = ''
          if a[0].respond_to?('join')
            a[0].each do |cell|
              j, k = get_cell(cell, col_num, true).split(',')
              light += "#{j}:{#{k}:'highlight'},"
            end
          else
            j, k = get_cell(a[0], col_num, true).split(',')
            light += "#{j}:{#{k}:'highlight'},"
          end

          if a[1].respond_to?('join')
            a[1].each do |cell|
              j, k = get_cell(cell, col_num, true).split(',')
              light += "#{j}:{#{k}:'highlight'},"
            end
          else
            j, k = get_cell(a[0], col_num, true).split(',')
            light += "#{j}:{#{k}:'highlight'},"
          end
          str =<<-EFJS

        if (#{left} != #{right}) {
            if ($('##{a[1].join}').length == 0) {
              $('<div id=#{a[1].join()}>#{a[2]}</div>').insertBefore($('##{self.object_id}'));
              $('##{a[1].join()}').addClass('alert alert-error');
              grid.setCellCssStyles("css#{a[1].join}", {
                  #{light.chop}
              })
            }

        }
        else {
            $('##{a[1].join()}').remove();
            grid.removeCellCssStyles("css#{a[1].join}");
        }
          EFJS
          result += str
        end
      end
      result
    end

    def flash_cell(sum_arr, col_num)
      result = ''
      sum_arr.each do |a|
        if a.size == 2
          left = conv_s(a[0], col_num)
          right = conv_s(a[1], col_num)
          result +=<<-FCJS
        grid.onCellChange.subscribe(function (e, args) {
            if (#{left} != #{right}) {
                grid.scrollRowIntoView(1, false);
                grid.flashCell(#{get_cell(a[0], col_num, true)}, 200);
            }
            var activeCellNode = args.cellNode;
            $(activeCellNode).attr("title", '');
        });
          FCJS
        end
      end
      result
    end

    def generate_header(headers)
      result = ''
      i = 0
      headers.each do |h|
        if h[2]
          h[1] ||= 100
          result << "columns.push({id: #{i},name: #{'\''+h[0]+'\''},field: #{i},width: #{h[1]},editor: FormulaEditor,sortable: false,asyncPostRender: formatThousandChar,validator: FieldValidator});\n"
        else
          result << "columns.push({id: #{i},name: #{'\''+h[0]+'\''},field: #{i},width: #{h[1]},editor: false});\n"
        end
        i +=1
      end
      result
    end

    def auto_write(arr, col_num)
      i = 1
      str = ''
      unless arr.blank?
        arr.each do |a|
          if !a[0].respond_to?('join') && a[1].is_a?(Array)
            str += "var val#{i} = 0"
            a[1].each do |num|
              str += "+parseFloat(#{get_cell(num, col_num)} || '0')"
            end
            str += ";\n"
            str += "grid.getCellNode(#{get_cell(a[0], col_num, true)}).innerHTML = val#{i};"
          end
          i += 1
        end
      end
      str
    end

  end

end
