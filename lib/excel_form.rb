#coding:utf-8

module ExcelForm
  class Ef
    attr_accessor :digit, :sum_arr, :headers, :auto_complete, :struct_data

    def initialize
      @digit = 2
      @sum_arr = []
      @headers = Array.new(6).map{['1',100,true]}
      @struct_data = ('0,0,0,0,0,0@'*6).chop
    end

    def form_builder
      col_num = self.headers.size
      result =<<JSCRIPT
        //转换千分符
    #{self.decimal_digit(self.digit)}
    //验证
    #{self.sum_validate(self.sum_arr, col_num)}

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
    #{self.generate_header(self.headers)}

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
        #{self.auto_write(self.auto_complete, col_num)}

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
        #{self.change_css(self.sum_arr, col_num)}
    }

    $(function () {
        var str = '#{self.struct_data}';
        var arr = str.split('@');
        for (var i = 0; i < arr.length; i++) {
            var a = arr[i].split(',');
            var d = (data[i] = {});
            for (var j = 0; j < a.length; j++) {
                d[j] = a[j];
            }

        }

        grid = new Slick.Grid("#myGrid", data, columns, options);

        #{self.flash_cell(self.sum_arr, col_num)}

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
        var check = true;
        var data_str = '';
        for (var i = 0; i < data.length; i++) {
            for (var j = 0; j < 100; j++) {
                //判断是否有元素高亮
                if(hasClass(grid.getCellNode(i, j), "highlight")) {
                    check = false;
                }
                //拼成数据
                data_str += data[i][j];
                if (j != #{col_num-1}) {
                    data_str += ','
                }
            }
            data_str += '@';
        }
        if (check) {
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

    def self.test_form(header, struct_data)
      result =<<JSCRIPT
    //转换千分符
    function cc(s) {
        if (/[^0-9\.]/.test(s)) return "";
        s = s.replace(/^(\d*)$/, "$1.");
        s = (s + "000000").replace(/(\d*\.\d\d\d\d\d\d)\d*/, "$1");
        s = s.replace(".", ",");
        var re = /(\d)(\d{3},)/;
        while (re.test(s))
            s = s.replace(re, "$1,$2");
        s = s.replace(/,(\d\d\d\d\d\d)$/, ".$1");
        return s.replace(/^\./, "0.")
    }
    //验证
    function FieldValidator(value) {
        if (isNaN(value)) {
//            if (value == null || value == undefined || !value.length) {
//            alert("只能输入数字！");
            return {valid: false, msg: "只能输入数字！"};
        } else {
            if (data[1][1] != (parseFloat(data[2][1]) + parseFloat(data[3][1]))) {
//                alert("营业收入应该为主营业务收入和其他业务收入之和！");
//                $(grid.getCellNode(1, 1)).popover('toggle');
                return {valid: true, msg: "营业收入应该为主营业务收入和其他业务收入之和！"};
            }

            return {valid: true, msg: null};
        }
    }


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
    var columns = [
//        {
//            id: "selector",
//            name: "",
//            field: "num",
//            width: 30
//        }
    ];
    //    data.getItemMetadata = function (row) {
    //        if (row === 0) {
    //            return {
    //                "columns": {
    //                    0: {
    //                        "colspan": "*"
    //                    }
    //                }
    //            };
    //        } else {
    //            return {
    //                "columns": {
    //                    "duration": {
    //                        "colspan": 3
    //                    }
    //                }
    //            };
    //        }
    //    }
    for (var i = 0; i < 6; i++) {
        var arr = '#{header}'.split(',');
        if (i % 3 == 0) {
            columns.push({
                id: i,
                name: arr[i],
                field: i,
                width: 270,
                editor: false,
                sortable: false,
                cssClass: "cell-title"
            });

        }

        else {
            columns.push({
                id: i,
                name: arr[i],
                field: i,
                width: 130,
                editor: FormulaEditor,
                sortable: false,
                asyncPostRender: formatThousandChar,
                validator: FieldValidator
            });

        }
//        columns.push({
//            id: i,
//            name: String.fromCharCode("b".charCodeAt(0) + (i / 26) | 0) +
//                    String.fromCharCode("b".charCodeAt(0) + (i % 26)),
//            field: i,
//            width: 60,
//            editor: FormulaEditor
//        });
    }

    /***
     * A proof-of-concept cell editor with Excel-like range selection and insertion.
     */
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
        var val1 = data[1][columns[1].field] || '0';
        var val2 = data[2][columns[1].field] || '0';
        var val3 = data[3][columns[1].field] || '0';
        var val4 = data[4][columns[1].field] || '0';
        var val5 = data[5][columns[1].field] || '0';
        var val6 = data[6][columns[1].field] || '0';
        var val = parseFloat(val1) + parseFloat(val2) + parseFloat(val3) + parseFloat(val4) + parseFloat(val5) + parseFloat(val6);
        //innerHTML只能改变页面显示，不能改变data实际的值
        grid.getCellNode(0, 1).innerHTML = val;

        //输入错误高亮闪烁
        if (data[1][1] != (parseFloat(data[2][1]) + parseFloat(data[3][1]))) {
            $('#error').html('营业收入应该为主营业务收入和其他业务收入之和！');
            $('#error').addClass('alert alert-error');
            grid.setCellCssStyles("yingyeshouru", {
                1: {
                    1: "highlight"
                },

                2: {
                    1: "highlight"
                },

                3: {
                    1: "highlight"
                }
            })
        }
        else {
            $('#error').html(' ');
            $('#error').removeClass('alert alert-error');
            grid.removeCellCssStyles("yingyeshouru")
        }


    }

    //        jQuery.getJSON('http://localhost:3000/sam/work_cards/demo', function(aa) {
    //            for (var i=0;i<2;i++){
    //                console.log(aa[i]);
    //            }
    //            console.log(aa);
    //        });

    $(function () {
        var str = '#{struct_data}';
        var arr = str.split('@');
        for (var i = 0; i < arr.length; i++) {
            var a = arr[i].split(',');
            var d = (data[i] = {});
            for (var j = 0; j < a.length; j++) {
                d[j] = a[j];
            }

        }

        grid = new Slick.Grid("#myGrid", data, columns, options);

        grid.onCellChange.subscribe(function (e, args) {
            if (data[1][1] != (parseFloat(data[2][1]) + parseFloat(data[3][1]))) {
                grid.scrollRowIntoView(1, false);
                grid.flashCell(1, 1, 200);
            }
            //
            var activeCellNode = args.cellNode;
            $(activeCellNode).attr("title", '');
//            console.log(args);
//            console.log(args.item[1]);
//            grid.invalidateRow(args.row);
//            grid.invalidateRow(args.cell);
//            grid.render();
        });

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

//                    grid.onAddNewRow.subscribe(function (e, args) {
//                        var item = args.item;
//                        var column = args.column;
//                        grid.invalidateRow(data.length);
//                        data.push(item);
//                        grid.updateRowCount();
//                        grid.render();
//                    });
        var handleValidationError = function (e, args) {
            var validationResult = args.validationResults;
            var activeCellNode = args.cellNode;
//            var editor = args.editor;
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
//        grid.onBeforeCellEditorDestroy.subscribe(destroyTip);


//        $("form").submit(
//                function () {
//                }
//        );

    })
    function hasClass(ele,cls) {
        return ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)'));
    }
    //数据有误，不能提交
    function submitFun() {
        var check = true;
        var data_str = '';
        for (var i = 0; i < data.length; i++) {
            for (var j = 0; j < 6; j++) {
                //判断是否有元素高亮
                if(hasClass(grid.getCellNode(i, j), "highlight")) {
                    check = false;
                }
                //拼成数据
                data_str += data[i][j];
                if (j != 5) {
                    data_str += ','
                }
            }
            data_str += '@';
        }
        if (check) {
            $("#new_data").val(data_str);
            $('form').submit();
        }
        else {
            alert('请确认数据的正确性！');
        }

    }
JSCRIPT
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
        if a.size == 2
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
            $('#error').html('错误！');
            $('#error').addClass('alert alert-error');
            grid.setCellCssStyles("yingyeshouru", {
                #{light.chop}
            })
        }
        else {
            $('#error').html(' ');
            $('#error').removeClass('alert alert-error');
            grid.removeCellCssStyles("yingyeshouru")
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
