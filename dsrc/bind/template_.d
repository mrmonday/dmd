module bind.template_;

import bind.root;
import bind.arraytypes;
import bind.dsymbol;

extern(C++):

interface Tuple : DmObject
{
}

interface TemplateDeclaration : ScopeDsymbol
{
}

interface TemplateParameter
{
}

interface TemplateTypeParameter : TemplateParameter
{
}

interface TemplateThisParameter : TemplateTypeParameter
{
}

interface TemplateValueParameter : TemplateParameter
{
}

interface TemplateAliasParameter : TemplateParameter
{
}

interface TemplateTupleParameter : TemplateParameter
{
}

interface TemplateInstance : ScopeDsymbol
{
}

interface TemplateMixin : TemplateInstance
{
}
